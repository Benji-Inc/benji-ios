//
//  WaitlistViewController.swift
//  Jibber
//
//  Created by Martin Young on 1/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Parse

class WaitlistViewController: DiffableCollectionViewController<MessageSequenceSection,
                             MessageSequenceItem,
                             MessageSequenceCollectionViewDataSource> {

    private(set) var conversationController: ConversationController?
    static let cid = ChannelId(type: .custom("waitlist"), id: "waitlist-id")

    let conversationCollectionView: ConversationCollectionView

    // Custom Input Accessory View
    lazy var messageInputAccessoryView: ConversationInputAccessoryView = {
        let inputView: ConversationInputAccessoryView = ConversationInputAccessoryView.fromNib()
        inputView.delegate = self.swipeInputDelegate
        inputView.textView.restorationIdentifier = "waitlist"
        return inputView
    }()
    lazy var swipeInputDelegate
    = SwipeableInputAccessoryMessageSender(viewController: self,
                                           collectionView: self.conversationCollectionView,
                                           isConversationList: true)

    override var inputAccessoryView: UIView? {
        return self.presentedViewController.isNil ? self.messageInputAccessoryView : nil
    }

    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController.isNil
    }

    init() {
        self.conversationCollectionView = ConversationCollectionView()
        super.init(with: self.conversationCollectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.collectionView.pin(.top, offset: .custom(self.view.height * 0.3))
        self.collectionView.width = Theme.getPaddedWidth(with: self.view.width)
        self.collectionView.height = self.view.height - self.collectionView.top
        self.collectionView.centerOnX()
    }

    // MARK: Data Loading

    override func getAllSections() -> [MessageSequenceSection] {
        return [.topMessages, .bottomMessages]
    }

    override func retrieveDataForSnapshot() async -> [MessageSequenceSection : [MessageSequenceItem]] {
        var data: [MessageSequenceSection: [MessageSequenceItem]] = [:]

        do {
            // TODO: Get the wait list conversation and load its messages.
        } catch {
            logDebug(error.code.description)
        }

        return data
    }
}

// MARK: - MessageSendingViewControllerType

extension WaitlistViewController: MessageSendingViewControllerType {

    func getCurrentMessageSequence() -> MessageSequence? {
        return self.conversationController?.conversation
    }

    func set(messageSequencePreparingToSend: MessageSequence?) {
        if let messageSequencePreparingToSend = messageSequencePreparingToSend {
            self.dataSource.shouldPrepareToSend = true
            self.dataSource.set(messageSequence: messageSequencePreparingToSend)
        }
    }

    func createNewConversation(_ sendable: Sendable) {
        // New conversations can't be created in the waitlist
        return
    }

    func sendMessage(_ message: Sendable) {
        guard let conversationController = self.conversationController else { return }

        Task {
            do {
                try await conversationController.createNewMessage(with: message)
            } catch {
                logError(error)
            }
        }.add(to: self.taskPool)
    }
}
