//
//  ThreadViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 12/27/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import StreamChat

class ThreadViewController: DiffableCollectionViewController<MessageSequenceSection,
                            MessageSequenceItem,
                            MessageSequenceCollectionViewDataSource>,
                            CollectionViewInputHandler,
                            DismissInteractableController {
    
    let blurView = BlurView()
    let parentMessageView = MessageContentView()
    let detailView = MessageDetailView()
    /// A view that shows where a message should be dragged and dropped to send.
    private let sendMessageDropZone = MessageDropZoneView()
    private let threadCollectionView = ThreadCollectionView()

    /// A controller for the message that all the replies in this thread are responding to.
    let messageController: ChatMessageController
    var parentMessage: Message? {
        return self.messageController.message
    }
    /// The reply to show when this view controller initially loads its data.
    private let startingReplyId: MessageId?

    private(set) var conversationController: ConversationController?

    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = self.collectionViewBottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    var indexPathForEditing: IndexPath?

    var inputTextView: InputTextView {
        return self.messageInputAccessoryView.textView
    }

    // Custom Input Accessory View
    lazy var messageInputAccessoryView: ConversationInputAccessoryView = {
        let view: ConversationInputAccessoryView = ConversationInputAccessoryView.fromNib()
        view.delegate = self.swipeInputDelegate
        view.textView.restorationIdentifier = "thread"
        return view
    }()
    lazy var swipeInputDelegate = SwipeableInputAccessoryMessageSender(viewController: self,
                                                                       collectionView: self.threadCollectionView,
                                                                       isConversationList: false)

    override var inputAccessoryView: UIView? {
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)

    init(channelID: ChannelId,
         messageID: MessageId,
         startingReplyId: MessageId?) {

        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)
        self.conversationController = ChatClient.shared.channelController(for: channelID,
                                                                             messageOrdering: .topToBottom)
        self.startingReplyId = startingReplyId

        super.init(with: self.threadCollectionView)

        self.threadCollectionView.threadLayout.dataSource = self.dataSource
        self.messageController.listOrdering = .bottomToTop
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.modalPresentationStyle = .overCurrentContext

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
        self.view.addSubview(self.parentMessageView)
        self.view.addSubview(self.detailView)
        self.detailView.alpha = 0

        self.collectionView.clipsToBounds = false

        self.dismissInteractionController.initialize(collectionView: self.collectionView)
    }

    private var shouldScrollToLastItem = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.parentMessageView.pinToSafeAreaTop()
        self.parentMessageView.centerOnX()

        self.detailView.width = self.parentMessageView.width - Theme.ContentOffset.standard.value
        self.detailView.height = MessageDetailView.height
        self.detailView.match(.top, to: .bottom, of: self.parentMessageView, offset: .short)
        self.detailView.centerOnX()

        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pinToSafeArea(.top, offset: .noOffset)
        self.collectionView.width = Theme.getPaddedWidth(with: self.view.width)
        self.collectionView.centerOnX()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.detailView.alpha = 1.0
        KeyboardManager.shared.addKeyboardObservers(with: self.inputAccessoryView)
        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if self.collectionView.isTracking {
            self.detailView.alpha = 0.0
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        KeyboardManager.shared.reset()
        self.resignFirstResponder()
    }

    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.topMessages, .bottomMessages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]

        do {
            try await self.messageController.loadPreviousReplies()

            guard let cid = self.parentMessage?.cid else { return [:] }

            let messages = self.messageController.replies.map { message in
                return MessageSequenceItem.message(cid: cid, messageID: message.id)
            }
            data[.bottomMessages] = Array(messages)
        } catch {
            logDebug(error)
        }
        
        return data
    }

    override func dataWasLoaded() {
        super.dataWasLoaded()

        self.subscribeToUpdates()

        /// Setting this here fixes issue with recursion during presentation.
        if let msg = self.messageController.message {
            self.detailView.configure(with: msg)
        }
    }

    override func getAnimationCycle(withData data: [MessageSequenceSection : [MessageSequenceItem]])
    -> AnimationCycle? {

        var startMessageIndex =
        guard let startingReplyId = self.startingReplyId else { return nil }
        let cid = self.messageController.cid

        let bottomMessages = data[.bottomMessages] ?? []
        let startMessageIndex
        = bottomMessages.firstIndex(of: .message(cid: cid, messageID: startingReplyId)) ?? 0

        let layout = self.threadCollectionView.threadLayout
        let scrollToOffset = CGPoint(x: 0, y: layout.itemHeight * CGFloat(startMessageIndex))
        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: false,
                              scrollToOffset: scrollToOffset)
    }

    func scrollToMessage(with messageId: MessageId) {
        Task {
            let cid = self.messageController.cid

            try? await self.messageController.loadNextReplies(including: messageId)

            let messageItem = MessageSequenceItem.message(cid: cid, messageID: messageId)

            guard let messageIndexPath = self.dataSource.indexPath(for: messageItem) else { return }

            let threadLayout = self.threadCollectionView.threadLayout
            guard let yOffset = threadLayout.itemFocusPositions[messageIndexPath] else { return }

            self.collectionView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
        }
    }
}
// MARK: - Messaging

extension ThreadViewController: MessageSendingViewControllerType {

    func set(shouldLayoutForDropZone: Bool) {
        self.threadCollectionView.threadLayout.layoutForDropZone = shouldLayoutForDropZone
        self.threadCollectionView.threadLayout.invalidateLayout()
    }

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.parentMessage
    }

    func set(messageSequencePreparingToSend: MessageSequence?, reloadData: Bool) {
        self.dataSource.shouldPrepareToSend = messageSequencePreparingToSend.exists

        if reloadData {
            guard let message = self.messageController.message else { return }
            self.dataSource.set(messageSequence: message)
        }
    }

    func sendMessage(_ message: Sendable) {
        Task {
            do {
                try await self.messageController.createNewReply(with: message)
            } catch {
                logDebug(error)
            }
        }
    }

    func createNewConversation(_ sendable: Sendable) {
        // Do nothing. New conversations can't be created from a thread view controller.
    }
}

// MARK: - TransitionableViewController

extension ThreadViewController: TransitionableViewController {
    
    var receivingPresentationType: TransitionType {
        return .message(self.parentMessageView)
    }

    var sendingDismissalType: TransitionType {
        return .message(self.parentMessageView)
    }
}

// MARK: - Updates and Subscription

extension ThreadViewController {

    func subscribeToUpdates() {
        self.dataSource.handleEditMessage = { cid, messageID in
            // TODO
        }

        self.collectionView.onDoubleTap { [unowned self] in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.messageInputAccessoryView.textView.$inputText.mainSink { [unowned self] _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
        }.store(in: &self.cancellables)

        self.messageController.messageChangePublisher.mainSink { [unowned self] changes in
            if let msg = self.messageController.message {
                self.parentMessageView.configure(with: msg)
                self.detailView.update(with: msg)
            }
        }.store(in: &self.cancellables)

        self.messageController.repliesChangesPublisher.mainSink { [unowned self] changes in
            guard let message = self.messageController.message else { return }
            self.dataSource.set(messageSequence: message)
        }.store(in: &self.cancellables)

        let members = self.messageController.message?.threadParticipants.filter { member in
            return member.id != ChatClient.shared.currentUserId
        } ?? []

        self.messageInputAccessoryView.textView.setPlaceholder(for: members, isReply: true)

        KeyboardManager.shared.$cachedKeyboardEndFrame.mainSink { [unowned self] frame in
            self.view.layoutNow()
        }.store(in: &self.cancellables)
    }
}
