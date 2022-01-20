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
                            DismissInteractableController {
    
    let blurView = BlurView()
    let parentMessageView = MessageContentView()
    let detailView = MessageDetailView()
    
    private let threadCollectionView = ThreadCollectionView()

    /// A controller for the message that all the replies in this thread are responding to.
    let messageController: ChatMessageController
    var parentMessage: Message? {
        return self.messageController.message
    }
    /// The reply to show when this view controller initially loads its data.
    private let startingReplyId: MessageId?

    private(set) var conversationController: ConversationController?
    let pullView = PullView()

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
    
    private(set) var topMostIndex: Int = 0
    
    @Published var state: ConversationUIState = .read

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
        
        self.view.backgroundColor = ThemeColor.B0.color.withAlphaComponent(0.5)

        self.modalPresentationStyle = .overCurrentContext

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
        self.view.addSubview(self.parentMessageView)
        self.view.addSubview(self.detailView)
        self.detailView.alpha = 0
        
        self.view.addSubview(self.pullView)

        self.collectionView.clipsToBounds = false

        self.dismissInteractionController.initialize(collectionView: self.collectionView)
        self.threadCollectionView.threadLayout.delegate = self
        
        KeyboardManager.shared.$currentEvent
            .mainSink { [weak self] currentEvent in
                guard let `self` = self else { return }
                switch currentEvent {
                case .willShow:
                    self.state = .write
                case .willHide:
                    self.state = .read
                default:
                    break
                }
            }.store(in: &self.cancellables)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.updateUI(for: state)
            }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        
        self.pullView.pinToSafeAreaTop()
        self.pullView.centerOnX()

        self.parentMessageView.match(.top, to: .bottom, of: self.pullView)
        self.parentMessageView.centerOnX()

        self.detailView.width = self.parentMessageView.width - Theme.ContentOffset.standard.value
        self.detailView.height = MessageDetailView.height
        self.detailView.match(.top, to: .bottom, of: self.parentMessageView, offset: .standard)
        self.detailView.centerOnX()

        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pinToSafeArea(.top, offset: .noOffset)
        self.collectionView.width = Theme.getPaddedWidth(with: self.view.width)
        self.collectionView.height = self.view.height - self.collectionView.top
        self.collectionView.centerOnX()
    }
    
    func updateUI(for state: ConversationUIState) {
        guard !self.isBeingOpen && !self.isBeingClosed else { return }
                        
        Task {
            await self.set(state: state)
        }.add(to: self.taskPool)
    }
    
    @MainActor
    private func set(state: ConversationUIState) async {
        self.threadCollectionView.threadLayout.uiState = state
        self.threadCollectionView.threadLayout.prepareForTransition(to: self.threadCollectionView.threadLayout)
        
        await UIView.awaitAnimation(with: .standard, animations: {
            self.threadCollectionView.threadLayout.finalizeLayoutTransition()
        })
    }

    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.topMessages, .bottomMessages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]

        do {
            try await self.messageController.loadPreviousReplies()

            if let startingReplyId = self.startingReplyId {
                try await self.messageController.loadNextReplies(including: startingReplyId)
            }

            let cid = self.messageController.cid

            let messages = self.messageController.replies.map { message in
                return MessageSequenceItem.message(cid: cid, messageID: message.id)
            }
            data[.bottomMessages] = Array(messages)
        } catch {
            logError(error)
        }
        
        return data
    }

    override func collectionViewDataWasLoaded() {
        super.collectionViewDataWasLoaded()

        self.subscribeToUpdates()

        /// Setting this here fixes issue with recursion during presentation.
        if let msg = self.messageController.message {
            self.detailView.configure(with: msg)
        }
        
        if let replyId = self.startingReplyId {
            self.animateReply(with: replyId)
        }
    }

    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<MessageSequenceSection,
                                    MessageSequenceItem>) -> AnimationCycle? {

        let cid = self.messageController.cid

        let startMessageIndex: Int
        if let startingReplyId = self.startingReplyId {
            startMessageIndex
            = snapshot.indexOfItem(.message(cid: cid, messageID: startingReplyId)) ?? 0
        } else {
            startMessageIndex = self.messageController.replies.count - 1
        }

        let layout = self.threadCollectionView.threadLayout
        let scrollToOffset = CGPoint(x: 0, y: layout.itemHeight * CGFloat(startMessageIndex))
        return AnimationCycle(inFromPosition: nil,
                              outToPosition: nil,
                              shouldConcatenate: false,
                              scrollToOffset: scrollToOffset)
    }

    func animateReply(with messageId: MessageId) {
        Task {
            let cid = self.messageController.cid

            try? await self.messageController.loadNextReplies(including: messageId)

            let messageItem = MessageSequenceItem.message(cid: cid, messageID: messageId)

            guard let messageIndexPath = self.dataSource.indexPath(for: messageItem) else { return }

            let threadLayout = self.threadCollectionView.threadLayout
            guard let yOffset = threadLayout.itemFocusPositions[messageIndexPath] else { return }

            self.collectionView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)

            if let cell = self.collectionView.cellForItem(at: messageIndexPath) {
                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = CGAffineTransform.init(scaleX: 1.05, y: 1.05)
                })

                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = .identity
                })
            }
        }.add(to: self.taskPool)
    }
}
// MARK: - Messaging

extension ThreadViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.parentMessage
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        self.dataSource.shouldPrepareToSend = messageSequencePreparingToSend.exists

        guard let message = self.messageController.message else { return }
        self.dataSource.set(messageSequence: message)
    }

    func sendMessage(_ message: Sendable) {
        Task {
            do {
                try await self.messageController.createNewReply(with: message)
            } catch {
                logError(error)
            }
        }.add(to: self.taskPool)
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

        KeyboardManager.shared.$cachedKeyboardEndFrame
            .removeDuplicates()
            .mainSink { [unowned self] frame in
                self.view.layoutNow()
            }.store(in: &self.cancellables)
    }
}

extension ThreadViewController: TimeMachineCollectionViewLayoutDelegate {
    
    func timeMachineCollectionViewLayout(_ layout: TimeMachineCollectionViewLayout,
                                         updatedFrontmostItemAt indexPath: IndexPath) {
        self.topMostIndex = indexPath.row
    }
}
