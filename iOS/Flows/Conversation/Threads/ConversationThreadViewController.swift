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

class ConversationThreadViewController: DiffableCollectionViewController<ConversationSection,
                                        ConversationItem,
                                        ConversationCollectionViewDataSource>,
                                        CollectionViewInputHandler {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    let messageController: ChatMessageController
    var message: Message! {
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
    lazy var messageInputAccessoryView = ConversationInputAccessoryView(with: self)

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
        super.init(with: ConversationThreadCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.dataSource.messageStyle = .thread

        self.view.insertSubview(self.blurView, belowSubview: self.collectionView)

        self.subscribeToUpdates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
    }

    // MARK: Data Loading

    override func getAllSections() -> [ConversationSection] {
        if let channelId = self.message.cid {
            return [ConversationSection(cid: channelId, parentMessageID: self.message.id)]
        }

        return []
    }

    override func retrieveDataForSnapshot() async -> [ConversationSection : [ConversationItem]] {
        var data: [ConversationSection: [ConversationItem]] = [:]

        do {
            try await self.messageController.loadPreviousReplies()
            let messages = Array(self.messageController.replies.asConversationCollectionItems)

            if let channelId = self.message.cid {
                let section = ConversationSection(cid: channelId, parentMessageID: self.message.id)
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
}

// MARK: - Updates and Subscription
extension ConversationThreadViewController {

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

        self.conversationController?.typingUsersPublisher.mainSink { [unowned self] users in
            let nonMeUsers = users.filter { user in
                return user.userObjectID != User.current()?.objectId
            }
            self.messageInputAccessoryView.updateTypingActivity(with: nonMeUsers)
        }.store(in: &self.cancellables)
    }
}
