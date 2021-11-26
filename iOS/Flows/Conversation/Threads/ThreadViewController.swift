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

class ThreadViewController: DiffableCollectionViewController<ConversationSection,
                            ConversationItem,
                            ConversationCollectionViewDataSource>,
                            CollectionViewInputHandler,
                            DismissInteractableController,
                            SwipeableInputAccessoryViewDelegate {

    let blurView = BlurView()
    let parentMessageView = MessageContentView()
    /// A view that shows where a message should be dragged and dropped to send.
    private let sendMessageOverlay = MessageDropZoneView()
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

        self.threadCollectionView.threadLayout?.dataSource = self
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

        self.collectionView.clipsToBounds = false

        self.dismissInteractionController.initialize(collectionView: self.collectionView)
    }

    override func handleDataBeingLoaded() {
        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.parentMessageView.pinToSafeArea(.top, padding: Theme.contentOffset)
        self.parentMessageView.centerOnX()

        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.pinToSafeArea(.top, padding: 0)
        self.collectionView.width = self.view.width * 0.8
        self.collectionView.centerOnX()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KeyboardManager.shared.addKeyboardObservers(with: self.inputAccessoryView)
        self.becomeFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        KeyboardManager.shared.reset()
        self.resignFirstResponder()
    }

    // MARK: Data Loading

    override func getAllSections() -> [ConversationSection] {
        if let channelId = self.parentMessage.cid {
            let placeholderSection = ConversationSection(sectionID: channelId.description,
                                                        parentMessageID: "Placeholder")
            return [placeholderSection,
                    ConversationSection(sectionID: channelId.description,
                                        parentMessageID: self.parentMessage.id)]
        }

        return []
    }

    override func retrieveDataForSnapshot() async -> [ConversationSection : [ConversationItem]] {
        var data: [ConversationSection: [ConversationItem]] = [:]

        do {
            try await self.messageController.loadPreviousReplies()
            let messages = Array(self.messageController.replies.asConversationCollectionItems)

            if let channelId = self.parentMessage.cid {
                let section = ConversationSection(sectionID: channelId.description,
                                                  parentMessageID: self.parentMessage.id)
                data[section] = []
                data[section]?.append(contentsOf: messages)
                if !self.messageController.hasLoadedAllPreviousReplies {
                    data[section]?.append(contentsOf: [.loadMore])
                }
            }
        } catch {
            logDebug(error)
        }
        
        return data
    }

    override func getAnimationCycle() -> AnimationCycle? {
        var cycle = super.getAnimationCycle()
        cycle?.shouldConcatenate = false
        // Scroll to the lastest reply.
        if let threadLayout = self.collectionView.collectionViewLayout as? ThreadCollectionViewLayout {
            let lastReplyIndex = clamp(self.messageController.replies.count - 1, min: 0)
            let yOffset = CGFloat(lastReplyIndex) * threadLayout.itemHeight
            cycle?.scrollToOffset = CGPoint(x: 0, y: yOffset)
        }

        return cycle
    }

    // MARK: - SwipeableInputAccessoryViewDelegate

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool) {
        if isEnabled {
            
            guard self.sendMessageOverlay.superview.isNil else { return }
            // Animate in the send overlay
            self.view.insertSubview(self.sendMessageOverlay, aboveSubview: self.collectionView)
            self.sendMessageOverlay.alpha = 0
            self.sendMessageOverlay.setState(.reply)
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageOverlay.alpha = 1
            }

            // Show the send message overlay so the user can see where to drag the message
            let overlayFrame = self.threadCollectionView.getMessageDropZoneFrame(convertedTo: self.view)
            self.sendMessageOverlay.frame = overlayFrame

            view.dropZoneFrame = view.convert(self.sendMessageOverlay.bounds, from: self.sendMessageOverlay)
        } else {
            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageOverlay.alpha = 0
            } completion: { didFinish in
                self.sendMessageOverlay.removeFromSuperview()
            }
        }
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = false
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

    func swipeableInputAccessoryDidFinishSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = true
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 updatedFrameOf textView: InputTextView) {
        // Do nothing.
    }
}

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
        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.messageInputAccessoryView.textView.$inputText.mainSink { _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
        }.store(in: &self.cancellables)

        self.messageController.repliesChangesPublisher.mainSink { [unowned self] changes in
            Task {
                await self.dataSource.update(with: changes,
                                             conversationController: self.messageController,
                                             collectionView: self.collectionView)
            }.add(to: self.taskPool)
        }.store(in: &self.cancellables)

        let members = self.messageController.message?.threadParticipants.filter { member in
            return member.id != ChatClient.shared.currentUserId
        } ?? []
        self.messageInputAccessoryView.textView.setPlaceholder(for: members, isReply: true)
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension ThreadViewController: TimeMachineCollectionViewLayoutDataSource {

    func getConversation(at indexPath: IndexPath) -> Conversation? {
        return self.conversationController?.conversation
    }

    func getMessage(at indexPath: IndexPath) -> Messageable? {
        return self.messageController.replies[indexPath.item]
    }
}
