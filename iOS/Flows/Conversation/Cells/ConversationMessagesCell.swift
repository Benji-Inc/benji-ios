//
//  MessageCell.swift
//  MessageCell
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import UIKit
import Combine

/// A cell to display the messages of a conversation.
/// The user's messages and other messages are put in two stacks (along the z-axis),
/// with the most recent messages at the front.
class ConversationMessagesCell: UICollectionViewCell {

    // Interaction handling
    var handleTappedMessage: ((ConversationId, MessageId, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationId, MessageId) -> Void)?

    var handleTappedConversation: ((MessageSequence) -> Void)?
    var handleDeleteConversation: ((MessageSequence) -> Void)?

    @Published var incomingTopmostMessage: ChatMessage?
    
    // CollectionView
    var collectionLayout: MessagesTimeMachineCollectionViewLayout {
        return self.collectionView.collectionViewLayout as! MessagesTimeMachineCollectionViewLayout
    }
    
    lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: MessagesTimeMachineCollectionViewLayout(with: .write))
        cv.keyboardDismissMode = .interactive
        cv.showsVerticalScrollIndicator = false
        return cv
    }()
    
    private lazy var dataSource = MessageSequenceCollectionViewDataSource(collectionView: self.collectionView)

    /// If true we should scroll to the last item in the collection in layout subviews.
    private var scrollToLastItemOnLayout: Bool = false

    //private var state: ConversationUIState = .read

    /// The conversation containing all the messages.
    var conversation: Conversation? {
        return self.conversationController?.conversation
    }
    private(set) var conversationController: ConversationController?
    private var shouldShowLoadMore: Bool {
        guard let conversationController = self.conversationController else {
            return false
        }

        if conversationController.messages.count < .messagesPageSize {
            return false
        }
        return !conversationController.hasLoadedAllPreviousMessages
    }
    /// A set of the current event subscriptions. Should be cleared out when the cell is reused.
    private var subscriptions = Set<AnyCancellable>()
    private var taskPool = TaskPool()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionLayout.dataSource = self.dataSource

        self.collectionView.decelerationRate = .fast
        self.collectionView.delegate = self
        self.collectionView.set(backgroundColor: .clear)

        // Allow message cells to scale in size without getting clipped.
        self.collectionView.clipsToBounds = false
        self.contentView.addSubview(self.collectionView)

        self.dataSource.handleTappedMessage = { [unowned self] cid, messageID, content in
            self.handleTappedMessage?(cid, messageID, content)
        }

        self.dataSource.handleEditMessage = { [unowned self] cid, messageID in
            self.handleEditMessage?(cid, messageID)
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] cid in
            Task {
                self.conversationController?.loadPreviousMessages()
            }
        }
        
        self.collectionLayout.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()

        if self.scrollToLastItemOnLayout {
            self.scrollToLastItemOnLayout = false

            self.collectionLayout.prepare()
            let maxOffset = self.collectionLayout.maxZPosition
            self.collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
            self.collectionLayout.invalidateLayout()
        }
    }
    
    /// WIP
    func transitionTo(state: ConversationUIState) {
//        guard self.collectionLayout.uiState != state else { return }
//
//        let newLayout = MessagesTimeMachineCollectionViewLayout(with: state)
//        newLayout.dataSource = self.dataSource
//        newLayout.delegate = self
//        newLayout.prepare()
//        self.collectionView.collectionViewLayout = newLayout
//
//        UIView.animate(withDuration: Theme.animationDurationSlow) {
//            self.collectionView.collectionViewLayout.prepareForTransition(to: newLayout)
//        } completion: { _ in
//            self.collectionView.collectionViewLayout.finalizeLayoutTransition()
//            self.scrollToLastItemOnLayout = true
//            self.layoutNow()
//        }
    }

    /// Configures the cell to display the given messages. The message sequence should be ordered newest to oldest.
    func set(conversation: Conversation) {
        // Create a new conversation controller if this is a different conversation than before.
        if conversation.cid != self.conversation?.cid {
            let conversationController = ChatClient.shared.channelController(for: conversation.cid)
            self.conversationController = conversationController
            self.subscribeToUpdates()

            if conversationController.messages.isEmpty {
                conversationController.synchronize()
            }
        }

        // Scroll to the last item when a new conversation is loaded.
        if self.dataSource.snapshot().itemIdentifiers.isEmpty {
            self.scrollToLastItemOnLayout = true
            self.setNeedsLayout()
        }

        self.dataSource.set(messageSequence: conversation, showLoadMore: self.shouldShowLoadMore)
    }

    func set(isPreparedToSend: Bool) {
        self.dataSource.shouldPrepareToSend = isPreparedToSend
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.dataSource.shouldPrepareToSend = false

        self.subscriptions.removeAll()
        Task {
            await self.taskPool.cancelAndRemoveAll()
        }

        // Remove all the items so the next message has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Update Subscriptions

    func subscribeToUpdates() {
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversationController = self.conversationController,
                      let cid = conversationController.cid else { return }

                var itemsToReconfigure: [MessageSequenceItem] = []
                for change in changes {
                    switch change {
                    case .update(let message, _):
                        itemsToReconfigure.append(.message(cid: cid, messageID: message.id))
                    default:
                        break
                    }
                }
                let conversation = conversationController.conversation
                self.dataSource.set(messageSequence: conversation,
                                    itemsToReconfigure: itemsToReconfigure,
                                    showLoadMore: self.shouldShowLoadMore)
            }.store(in: &self.subscriptions)
    }

    func scrollToMessage(with messageId: MessageId) async {
        let task = Task {
            guard let conversationController = self.conversationController,
                  let cid = conversationController.cid else { return }

            try? await conversationController.loadNextMessages(including: messageId)

            guard !Task.isCancelled else { return }

            let messageItem = MessageSequenceItem.message(cid: cid, messageID: messageId)

            guard let messageIndexPath = self.dataSource.indexPath(for: messageItem) else { return }

            guard let yOffset = self.collectionLayout.itemFocusPositions[messageIndexPath] else { return }

            self.collectionView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)

            await Task.sleep(seconds: Theme.animationDurationStandard)
        }
        task.add(to: self.taskPool)

        await task.value
    }

    // MARK: - Drop Zone Helpers

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.collectionLayout.getDropZoneFrame()

        return self.collectionView.convert(dropZoneFrame, to: targetView)
    }

    func setDropZone(isShowing: Bool) {
        self.collectionLayout.layoutForDropZone = isShowing
    }

    func getBottomFrontmostCell() -> MessageCell? {
        return self.collectionLayout.getBottomFrontmostCell()
    }
}

extension ConversationMessagesCell: UICollectionViewDelegate {
    
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? MessageCell else { return }

        switch item {
        case .message(cid: let cid, messageID: let messageID):
            self.handleTappedMessage?(cid, messageID, cell.content)
        case .loadMore, .placeholder:
            break
        }
    }
}

extension ConversationMessagesCell: TimeMachineCollectionViewLayoutDelegate {

    func timeMachineCollectionViewLayout(_ layout: TimeMachineCollectionViewLayout,
                                         updatedFrontmostItemAt indexPath: IndexPath) {
        
        guard indexPath.section == 0, let item = self.dataSource.itemIdentifier(for: indexPath) else {
            self.incomingTopmostMessage = nil
            return
        }

        switch item {
        case .message(cid: let cid, messageID: let messageID):
            let message = ChatClient.shared.message(cid: cid, id: messageID)
            self.incomingTopmostMessage = message
        case .loadMore, .placeholder:
            break
        }
    }
}
