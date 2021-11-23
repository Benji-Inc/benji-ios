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
                            CollectionViewInputHandler, DismissInteractableController {

    let blurView = BlurView()
    let parentMessageView = MessageContentView()

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
        let collectionView = ThreadCollectionView()
        super.init(with: collectionView)

        collectionView.threadLayout.dataSource = self
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

        self.dismissInteractionController.initialize(interactionView: self.collectionView)
    }

    override func handleDataBeingLoaded() {
        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.parentMessageView.pinToSafeArea(.top, padding: Theme.contentOffset)
        self.parentMessageView.centerOnX()

        self.collectionView.pinToSafeArea(.top, padding: 0)
        self.collectionView.width = self.view.width * 0.8
        self.collectionView.centerOnX()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

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
