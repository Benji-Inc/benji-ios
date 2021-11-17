//
//  ConversationViewController.swift
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
                                        CollectionViewInputHandler {

    private let blurView = BlurView()
    private let parentMessageView = ThreadMessageCell()
    /// A view positioned behind the parent message to separate it from the rest of the messages.
    private let parentMessageBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

    /// A controller for the message that all the replies in this thread are responding to.
    let messageController: ChatMessageController
    var parentMessage: Message! {
        return self.messageController.message
    }

    private(set) var conversationController: ChatChannelController?

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
        view.conversation = self.messageController.conversation
        return view
    }()

    override var inputAccessoryView: UIView? {
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    init(channelID: ChannelId, messageID: MessageId) {
        self.messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)
        self.conversationController = ChatClient.shared.channelController(for: channelID,
                                                                             messageOrdering: .topToBottom)
        super.init(with: ThreadCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)
        self.view.addSubview(self.parentMessageBlurView)
        self.view.addSubview(self.parentMessageView)

        self.parentMessageView.set(message: self.parentMessage, replies: [], totalReplyCount: 0)
        self.parentMessageView.setAuthor(with: self.parentMessage.avatar,
                                         showTopLine: false,
                                         showBottomLine: false)

        self.subscribeToUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        let headerHeight: CGFloat = 120

        self.parentMessageBlurView.pin(.top, padding: Theme.contentOffset)
        self.parentMessageBlurView.width = self.view.width - Theme.contentOffset.doubled
        self.parentMessageBlurView.height = headerHeight
        self.parentMessageBlurView.centerOnX()
        self.parentMessageBlurView.roundCorners()

        self.parentMessageView.width = self.view.width * 0.8
        self.parentMessageView.height = headerHeight - Theme.contentOffset.doubled
        self.parentMessageView.match(.top, to: .top, of: self.parentMessageBlurView, offset: Theme.contentOffset)
        self.parentMessageView.centerOnX()

        self.collectionView.contentInset.top = headerHeight + Theme.contentOffset
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
            return [ConversationSection(sectionID: channelId.description,
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
        cycle?.scrollToIndexPath = IndexPath(item: 0, section: 0)
        cycle?.scrollPosition = .bottom
        return cycle
    }
}

// MARK: - Updates and Subscription
extension ThreadViewController {

    func subscribeToUpdates() {
        self.addKeyboardObservers()

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
            }
        }.store(in: &self.cancellables)

        self.dataSource.handleDeleteMessage = { [unowned self] message in
            self.conversationController?.deleteMessage(message.id)
        }
    }
}