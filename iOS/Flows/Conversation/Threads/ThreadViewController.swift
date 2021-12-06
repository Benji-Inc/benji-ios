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
                            DismissInteractableController,
                            SwipeableInputAccessoryViewDelegate {
    
    let blurView = BlurView()
    let parentMessageView = MessageContentView()
    let detailView = MessageDetailView()
    /// A view that shows where a message should be dragged and dropped to send.
    private let sendMessageDropZone = MessageDropZoneView()
    private let threadCollectionView = ThreadCollectionView()

    /// A controller for the message that all the replies in this thread are responding to.
    let messageController: ChatMessageController
    var parentMessage: Message! {
        return self.messageController.message
    }

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
        view.delegate = self
        view.textView.restorationIdentifier = "thread"
        return view
    }()

    override var inputAccessoryView: UIView? {
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    lazy var dismissInteractionController = PanDismissInteractionController(viewController: self)

    init(channelID: ChannelId, messageID: MessageId) {
        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)
        self.conversationController = ChatClient.shared.channelController(for: channelID,
                                                                             messageOrdering: .topToBottom)
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

        if let msg = self.messageController.message {
            self.detailView.configure(with: msg)
        }

        self.collectionView.clipsToBounds = false

        self.dismissInteractionController.initialize(collectionView: self.collectionView)
    }

    override func handleDataBeingLoaded() {
        self.subscribeToUpdates()
    }

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

            guard let cid = self.parentMessage.cid else { return [:] }

            let messages = self.messageController.replies.map { message in
                return MessageSequenceItem(channelID: cid, messageID: message.id)
            }
            data[.bottomMessages] = Array(messages)
        } catch {
            logDebug(error)
        }
        
        return data
    }

    override func getAnimationCycle() -> AnimationCycle? {
        return nil
    }

    // MARK: - SwipeableInputAccessoryViewDelegate

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool) {
        if isEnabled {
            self.showDropZone(for: view)
        } else {
            self.hideDropZone()
        }
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = false

        self.dataSource.prepareForSend = true

        guard let message = self.messageController.message else { return }
        self.dataSource.set(messageSequence: message)
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdate sendable: Sendable,
                                 withPreviewFrame frame: CGRect) {
        // Do nothing.
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 triggeredSendFor sendable: Sendable,
                                 withPreviewFrame frame: CGRect) -> Bool {

        // Ensure that the preview has been dragged far up enough to send.
        let dropZoneFrame = view.dropZoneFrame
        let shouldSend = dropZoneFrame.bottom > frame.centerY

        guard shouldSend else {
            return false
        }

        Task {
            await self.send(object: sendable)
        }.add(to: self.taskPool)

        return true
    }

    func showDropZone(for view: SwipeableInputAccessoryView) {
        guard self.sendMessageDropZone.superview.isNil else { return }
        // Animate in the send overlay
        self.view.addSubview(self.sendMessageDropZone)
        self.sendMessageDropZone.alpha = 0
        self.sendMessageDropZone.setState(.newMessage, messageColor: self.threadCollectionView.getDropZoneColor())

        let cell = self.threadCollectionView.getBottomFrontMostCell()
        self.threadCollectionView.setDropZone(isShowing: true)
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageDropZone.alpha = 1
            cell?.content.textView.alpha = 0
            cell?.content.authorView.alpha = 0
        }

        // Show the send message overlay so the user can see where to drag the message
        let overlayFrame = self.threadCollectionView.getMessageDropZoneFrame(convertedTo: self.view)
        self.sendMessageDropZone.frame = overlayFrame

        view.dropZoneFrame = view.convert(self.sendMessageDropZone.bounds, from: self.sendMessageDropZone)
    }

    func hideDropZone() {
        let cell = self.threadCollectionView.getBottomFrontMostCell()
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageDropZone.alpha = 0
            cell?.content.textView.alpha = 1.0
            cell?.content.authorView.alpha = 1.0
        } completion: { didFinish in
            self.threadCollectionView.setDropZone(isShowing: false)
            self.sendMessageDropZone.removeFromSuperview()
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didFinishSwipeSendingSendable didSend: Bool) {

        self.collectionView.isUserInteractionEnabled = true

        self.dataSource.prepareForSend = false

        if !didSend, let message = self.messageController.message {
            self.dataSource.set(messageSequence: message)
        }
    }
}

// MARK: - Messaging

extension ThreadViewController {

    func handle(attachment: Attachment, body: String) {
        Task {
            do {
                let kind = try await AttachmentsManager.shared.getMessageKind(for: attachment, body: body)
                let object = SendableObject(kind: kind, context: .passive)
                await self.send(object: object)
            } catch {
                logDebug(error)
            }
        }.add(to: self.taskPool)
    }

    @MainActor
    func send(object: Sendable) async {
        do {
            try await self.messageController.createNewReply(with: object)
        } catch {
            logDebug(error)
        }
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
        self.dataSource.handleEditMessage = { [unowned self] item in
            // TODO
        }

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
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
                self.detailView.configure(with: msg)
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
