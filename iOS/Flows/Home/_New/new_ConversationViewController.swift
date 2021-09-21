//
//  ConversationViewController.swift
//  ConversationViewController
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class new_ConversationViewController: FullScreenViewController,
                                      UICollectionViewDelegate,
                                      UICollectionViewDelegateFlowLayout {

    private lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    var collectionView = CollectionView(layout: new_ConversationCollectionViewLayout())

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    var conversation: Conversation! { return self.conversationController?.channel }
    private(set) var conversationController: ChatChannelController!

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

        self.view.insertSubview(self.blurView, belowSubview: self.contentContainer)
        self.contentContainer.addSubview(self.collectionView)
        self.collectionView.decelerationRate = .fast
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        once(caller: self, token: "initializeCollectionView") {
            Task {
                self.setupInputHandlers()
                await self.loadInitialMessages()
                self.subscribeToConversationUpdates()
            }
        }
    }

    private func setupInputHandlers() {
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

    // MARK: - UICollectionViewDelegate

    /// If true, the conversation controller is currently loading messages.
    @Atomic private var isLoadingMessages = false
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {

        // If all the messages are loaded, there's no need to fetch more.
        guard !self.conversationController.hasLoadedAllPreviousMessages else { return }

        // Start fetching new messages once the user is nearing the end of the list.
        guard indexPath.row < 2 else { return }

        Task {
            guard !isLoadingMessages else { return }

            self.isLoadingMessages = true
            do {
                let oldestMessageID = self.conversationController.messages.first?.id
                try await self.conversationController.loadPreviousMessages(before: oldestMessageID)
            } catch {
                logDebug(error)
            }
            self.isLoadingMessages = false
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        // Always scroll so that a message is centered when we stop scrolling.
        var newXOffset = CGFloat.greatestFiniteMagnitude
        let targetOffset = targetContentOffset.pointee

        let targetRect = CGRect(x: targetOffset.x,
                                y: targetOffset.y,
                                width: scrollView.width,
                                height: scrollView.height)

        let layout = self.collectionView.collectionViewLayout
        guard let layoutAttributes = layout.layoutAttributesForElements(in: targetRect) else {
            return
        }

        // Find the item whose center is closest to the proposed offset
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - targetOffset.x) < abs(newXOffset - targetOffset.x) {
                newXOffset = possibleNewOffset
            }
        }

        targetContentOffset.pointee = CGPoint(x: newXOffset, y: targetOffset.y)
    }
}

// MARK: - Message Loading and Updates

extension new_ConversationViewController {

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

    func subscribeToConversationUpdates() {
        self.conversationController.messagesChangesPublisher.mainSink { [unowned self] changes in
            Task {
                await self.updateMessages(with: changes)
            }
        }.store(in: &self.cancellables)
    }

    func updateMessages(with changes: [ListChange<ChatMessage>]) async {

        guard let conversationController = self.conversationController else { return }

        var snapshot = self.dataSource.snapshot()

        // If there's more than one change, reload all of the data.
        guard changes.count == 1 else {
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .basic(conversation.cid)))
            snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                 toSection: .basic(conversation.cid))
            await self.dataSource.applySnapshotKeepingVisualOffset(snapshot,
                                                                   collectionView: self.collectionView)
            return
        }

        // If this gets set to true, we should scroll to the most recent message after applying the snapshot
        var scrollToLatestMessage = false

        for change in changes {
            switch change {
            case .insert(let message, let index):
                let section = ConversationCollectionSection.basic(self.conversation.cid)
                snapshot.insertItems([.message(message.id)],
                                     in: section,
                                     atIndex: index.item)
                scrollToLatestMessage = true
            case .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .basic(conversation.cid)))
                snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                     toSection: .basic(conversation.cid))
            case .update(let message, _):
                snapshot.reloadItems([message.asConversationCollectionItem])
            case .remove(let message, _):
                snapshot.deleteItems([message.asConversationCollectionItem])
            }
        }

        await Task.onMainActorAsync { [snapshot = snapshot, scrollToLatestMessage = scrollToLatestMessage] in
            self.dataSource.apply(snapshot)

            if scrollToLatestMessage {
                let items = snapshot.itemIdentifiers(inSection: .basic(self.conversation.cid))
                let lastIndex = IndexPath(item: items.count - 1, section: 0)
                self.collectionView.scrollToItem(at: lastIndex, at: .centeredHorizontally, animated: true)
            }
        }
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
