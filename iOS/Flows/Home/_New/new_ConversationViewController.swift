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

    var conversation: Conversation? {
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

        self.setupHandlers()
        self.subscribeToUpdates()
    }

    private func setupHandlers() {
        self.addKeyboardObservers()

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        if let conversation = self.conversationController?.channel {
            self.load(conversation: conversation)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
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
            Task {
                await self.send(object: sendable)
            }
        } else {
            self.update(object: sendable)
        }
    }

    func load(conversation: Conversation) {
        self.loadMessages(for: conversation)
    }

    @MainActor
    func send(object: Sendable) async {
        guard let conversation = self.conversation else { return }

        do {
            if case .text(let body) = object.kind {
                let controller = ChatClient.shared.channelController(for: conversation.cid)
                try await controller.createNewMessage(text: body)

                self.collectionView.scrollToEnd()
            }
        } catch {
            logDebug(error)
        }
    }

    func update(object: Sendable) {
        //        if let updatedMessage = MessageSupplier.shared.update(object: object) {
        //            self.indexPathForEditing = nil
        //            self.collectionViewManager.updateItemSync(with: updatedMessage)
        //            self.messageInputAccessoryView.reset()
        //        }
    }
}

extension new_ConversationViewController {

    func loadMessages(for conversation: Conversation) {
        Task {
            do {
                let controller = ChatClient.shared.channelController(for: conversation.cid)
                try await controller.loadPreviousMessages()
                let messages: [ChatMessage] = controller.messages.reversed()

                var snapshot = self.dataSource.snapshot()
                snapshot.appendSections([.messages])
                snapshot.appendItems(messages.asConversationCollectionItems, toSection: .messages)

                await self.dataSource.apply(snapshot)
            } catch {
                logDebug(error)
            }
        }
    }

    func subscribeToUpdates() {
        guard let conversation = self.conversation else { return }

        let controller = ChatClient.shared.channelController(for: conversation.cid)
        controller.messagesChangesPublisher.mainSink { [weak self] (changes: [ListChange<ChatMessage>]) in
            guard let `self` = self else { return }

            for change in changes {
                switch change {
                case .insert(let message, index: let index):
                    return
                case .move(_, fromIndex: let fromIndex, toIndex: let toIndex):
                    return
                case .update(_, index: let index):
                    return
                case .remove(_, index: let index):
                    return
                }
            }
        }.store(in: &self.cancellables)
    }

//        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
//            guard let `self` = self else { return }
//            guard let memberUpdate = update, ConversationSupplier.shared.isConversationEqualToActiveConversation(conversation: memberUpdate.conversation) else { return }
//
//            switch memberUpdate.status {
//            case .joined, .left:
//                memberUpdate.conversation.getMembersCount { [unowned self] (result, count) in
//                    self.collectionViewManager.numberOfMembers = Int(count)
//                }
//            case .changed:
//                break
//            case .typingEnded:
//                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
//                    self.collectionViewManager.userTyping = nil
//                    self.collectionViewManager.setTypingIndicatorViewHidden(true)
//                }
//            case .typingStarted:
//                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
//                    Task {
//                        guard let user = try? await memberUpdate.member.getMemberAsUser() else { return }
//                        self.collectionViewManager.userTyping = user
//                        self.collectionViewManager.setTypingIndicatorViewHidden(false, performUpdates: nil)
//                    }
//                }
//            }
//        }.store(in: &self.cancellables)
}
