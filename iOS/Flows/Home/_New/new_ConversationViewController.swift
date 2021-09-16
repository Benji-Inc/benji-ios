//
//  ConversationViewController.swift
//  ConversationViewController
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol new_ConversationViewControllerDelegate: AnyObject {

}

class new_ConversationViewController: FullScreenViewController, CollectionViewInputHandler {

    private lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    let collectionView = CollectionView(layout: ConversationCollectionViewLayout())
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    var conversation: Conversation! {
        return self.conversationController?.channel
    }
    private(set) var conversationController: ChatChannelController?

    var collectionViewBottomInset: CGFloat = 0 {
        didSet {
            self.collectionView.contentInset.bottom = self.collectionViewBottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = self.collectionViewBottomInset
        }
    }

    // TODO: Remove this if not needed
    var indexPathForEditing: IndexPath?
    var inputTextView: InputTextView {
        return self.messageInputAccessoryView.textView
    }

    // Custom Input Accessory View
    lazy var messageInputAccessoryView = InputAccessoryView(with: self)

    override var inputAccessoryView: UIView? {
        // This is a hack to make the input hide during the presentation of the image picker.
        self.messageInputAccessoryView.alpha = UIWindow.topMostController() == self ? 1.0 : 0.0
        return self.messageInputAccessoryView
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    init(conversation: Conversation?) {
        if let conversation = conversation {
            self.conversationController = ChatClient.shared.channelController(for: conversation.cid)
        }

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.blurView)
        self.view.addSubview(self.collectionView)

        self.subscribeToUpdates()
        self.setupHandlers()

        self.loadMessages()
    }

    private func setupHandlers() {
        self.addKeyboardObservers()

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()
    }
}

extension new_ConversationViewController: SwipeableInputAccessoryViewDelegate {

    func handle(attachment: Attachment, body: String) {
        Task {
            do {
                let kind = try await AttachmentsManager.shared.getMessageKind(for: attachment, body: body)
                let object = SendableObject(kind: kind, context: .passive)
                await self.send(object: object)
            } catch {
                logDebug(error)
            }
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        if sendable.previousMessage.isNil {
            Task { await self.send(object: sendable) }
        } else {
            Task { await self.update(object: sendable) }
        }
    }

    func send(object: Sendable) async {
        do {
            try await self.conversationController?.createNewMessage(with: object)
        } catch {
            logDebug(error)
        }
    }

    func update(object: Sendable) async {
        do {
            guard let messageID = object.previousMessage?.id else { return }
            let messageController = ChatClient.shared.messageController(cid: self.conversation!.cid,
                                                                        messageId: messageID)
            try await messageController.editMessage(with: object)
        } catch {
            logDebug(error)
        }
    }
}

extension new_ConversationViewController {

    func loadMessages() {
        Task {
            do {
                guard let controller = self.conversationController else { return }

                let messages: [ChatMessage] = Array(controller.messages)

                var snapshot = self.dataSource.snapshot()
                snapshot.appendSections([.basic(controller.cid!)])
                snapshot.appendItems(messages.asConversationCollectionItems,
                                     toSection: .basic(controller.cid!))

                await self.dataSource.apply(snapshot, animatingDifferences: false)

                await Task.sleep(seconds: 2)
                let oldestMessage = controller.messages.last
                try await controller.loadPreviousMessages(before: oldestMessage?.id)
            } catch {
                logDebug(error)
            }
        }
    }

    func subscribeToUpdates() {
        guard let controller = self.conversationController else { return }

        controller.delegate = self
    }
}


extension new_ConversationViewController: ChatChannelControllerDelegate {

    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(_ channelController: ChatChannelController,
                           didUpdateMessages changes: [ListChange<ChatMessage>]) {

        var snapshot = self.dataSource.snapshot()

        for change in changes {
            switch change {
            case .insert:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .basic(channelController.cid!)))
                let messages = Array(channelController.messages)
                snapshot.appendItems(messages.asConversationCollectionItems, toSection: .basic(channelController.cid!))
                self.dataSource.apply(snapshot)
                return

            case .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .basic(channelController.cid!)))
                let messages = Array(channelController.messages)
                snapshot.appendItems(messages.asConversationCollectionItems, toSection: .basic(channelController.cid!))
                self.dataSource.apply(snapshot)
                return

            case .update(let message, _):
                snapshot.reloadItems([message.asConversationCollectionItem])
            case .remove(let message, _):
                snapshot.deleteItems([message.asConversationCollectionItem])
            }
        }

        self.dataSource.apply(snapshot)
    }
}
