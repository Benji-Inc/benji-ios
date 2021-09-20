//
//  ConversationViewController.swift
//  ConversationViewController
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class new_ConversationViewController: FullScreenViewController, CollectionViewInputHandler {

    private lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    let collectionView = CollectionView(layout: ConversationCollectionViewLayout())

    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    var conversation: Conversation! { return self.conversationController?.channel }
    private(set) var conversationController: ChatChannelController!

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
            self.conversationController
            = ChatClient.shared.channelController(for: conversation.cid, messageOrdering: .bottomToTop)
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "intializeCollectionView") {
            Task {
                self.setupInputHandlers()
                await self.loadInitialMessages()
                self.subscribeToConversationUpdates()
            }
        }
    }

    private func setupInputHandlers() {
        self.addKeyboardObservers()

        self.collectionView.delegate = self

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.dataSource.handleDeleteMessage = { [unowned self] message in
            self.conversationController.deleteMessage(message.id)
        }
    }
}

extension new_ConversationViewController: UICollectionViewDelegate {


    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {

        // If all the messages are loaded, no need to fetch more.
        guard !self.conversationController.hasLoadedAllPreviousMessages else { return }

        // Start fetching new messages once the user is nearing the end of the list.
        guard indexPath.row < 10 else { return }

        Task {
            do {
                let oldestMessageID = self.conversationController.messages.first?.id
                try await self.conversationController.loadPreviousMessages(before: oldestMessageID)
            } catch {
                logDebug(error)
            }
        }
    }
}

extension new_ConversationViewController {

    func subscribeToConversationUpdates() {
        self.conversationController?.delegate = self
    }

    @MainActor
    func loadInitialMessages() async {
        guard let controller = self.conversationController else { return }

        let messages = controller.messages

        var snapshot = self.dataSource.snapshot()
        snapshot.appendSections([.basic(conversation.cid)])
        snapshot.appendItems(messages.asConversationCollectionItems)

        let animationCycle = AnimationCycle(inFromPosition: .left,
                                            outToPosition: .right,
                                            shouldConcatenate: true,
                                            scrollToEnd: true)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)
    }
}

extension new_ConversationViewController: ChatChannelControllerDelegate {

    /// The controller observed changes in the `Messages` of the observed channel.
    func channelController(_ channelController: ChatChannelController,
                           didUpdateMessages changes: [ListChange<ChatMessage>]) {

        var snapshot = self.dataSource.snapshot()

        for change in changes {
            switch change {
            case .insert, .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .basic(conversation.cid)))
                snapshot.appendItems(channelController.messages.asConversationCollectionItems,
                                     toSection: .basic(conversation.cid))
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

extension new_ConversationViewController: SwipeableInputAccessoryViewDelegate {

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        Task {
            if sendable.previousMessage.isNil {
                await self.send(object: sendable)
            } else {
                await self.update(object: sendable)
            }
        }
    }

    private func send(object: Sendable) async {
        do {
            try await self.conversationController?.createNewMessage(with: object)
        } catch {
            logDebug(error)
        }
    }

    private func update(object: Sendable) async {
        do {
            try await self.conversationController?.editMessage(with: object)
        } catch {
            logDebug(error)
        }
    }
}
