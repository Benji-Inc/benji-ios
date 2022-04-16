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

protocol ConversationUIStateSettable {
    func set(state: ConversationUIState)
}

/// A cell to display the messages of a conversation.
/// The user's messages and other messages are put in a stack (along the z-axis),
/// with the most recent messages at the front.
class ConversationMessagesCell: UICollectionViewCell, ConversationUIStateSettable, UICollectionViewDelegate {

    // Interaction handling

    var messageContentDelegate: MessageContentDelegate? {
        get { return self.dataSource.messageContentDelegate }
        set { self.dataSource.messageContentDelegate = newValue }
    }
    var handleCollectionViewTapped: CompletionOptional = nil
    
    // Collection View

    private var collectionLayout: MessagesTimeMachineCollectionViewLayout {
        return self.collectionView.conversationLayout
    }
    private lazy var collectionView = ConversationCollectionView()
    private lazy var dataSource = MessageSequenceCollectionViewDataSource(collectionView: self.collectionView)

    /// The conversation containing all the messages.
    var conversation: Conversation? {
        return self.conversationController?.conversation
    }
    private(set) var conversationController: ConversationController?
    private var shouldShowLoadMore: Bool {
        guard let conversationController = self.conversationController else { return false }

        if conversationController.messages.count < .messagesPageSize {
            return false
        }
        return !conversationController.hasLoadedAllPreviousMessages
    }
    /// A set of the current event subscriptions. Should be cleared out when the cell is reused.
    private var subscriptions = Set<AnyCancellable>()
    /// A reference to the current task that scrolls to a specific message
    private var scrollToMessageTask: Task<Void, Never>?
    /// If true we should scroll to the last item in the collection in layout subviews.
    private var scrollToLastMessageIfNeccessary: Bool = false

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.configureCollectionLayout(for: .read)
        self.collectionLayout.dataSource = self.dataSource
        self.collectionView.delegate = self

        self.contentView.addSubview(self.collectionView)
        
        self.collectionView.backView.didSelect { [unowned self] in
            self.handleCollectionViewTapped?()
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] cid in
            self.conversationController?.loadPreviousMessages(limit: .messagesPageSize)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()

        if self.scrollToLastMessageIfNeccessary {
            self.scrollToLastMessageIfNeccessary = false
            self.scrollToLastMessage()
        }
    }

    private func scrollToLastMessage() {
        let maxOffset = self.collectionLayout.maxZPosition
        self.collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
    }

    /// Configures the cell to display the given messages. The message sequence should be ordered newest to oldest.
    func set(conversation: Conversation, shouldPrepareToSend: Bool) {
        // Create a new conversation controller if this is a different conversation than before.
        var updatedController = false
        if conversation.cid != self.conversation?.cid {
            updatedController = true
            let conversationController = ChatClient.shared.channelController(for: conversation.cid)
            self.conversationController = conversationController
            self.subscribeToUpdates()

            if conversationController.messages.isEmpty {
                conversationController.synchronize()
            }
        }

        // Do nothing if neither the controller nor the prepareToSend state were changed.
        if !updatedController && self.dataSource.shouldPrepareToSend == shouldPrepareToSend  {
            return
        }

        self.dataSource.shouldPrepareToSend = shouldPrepareToSend
        
        guard let conversationController = self.conversationController else { return }

        // Scroll to the last item when a new conversation is loaded.
        if self.dataSource.snapshot().itemIdentifiers.isEmpty {
            self.scrollToLastMessageIfNeccessary = true
            self.setNeedsLayout()
        }

        self.dataSource.set(messagesController: conversationController, showLoadMore: self.shouldShowLoadMore)
    }

    func set(state: ConversationUIState) {
        let stateBeforeUpdate = self.collectionLayout.uiState

        self.configureCollectionLayout(for: state)

        Task {
            guard state != stateBeforeUpdate else { return }

            await self.dataSource.reconfigureAllItems()

            guard state == .write else { return }
            // Auto scroll to the latest message when in the write mode.
            let maxOffset = self.collectionLayout.maxZPosition
            self.collectionView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
        }
    }

    private func configureCollectionLayout(for state: ConversationUIState) {
        switch state {
        case .read:
            self.collectionLayout.spacingKeyPoints = [0, 96, 144, 192]
        case .write:
            self.collectionLayout.spacingKeyPoints = [0, 8, 14, 16]
        }
        
        self.collectionLayout.uiState = state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.conversationController = nil

        self.dataSource.shouldPrepareToSend = false

        self.subscriptions.removeAll()
        self.scrollToMessageTask?.cancel()

        // Remove all the items so the next conversation loaded has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        guard let attributes = layoutAttributes as? ConversationsMessagesCellAttributes else { return }

        self.collectionView.isUserInteractionEnabled = attributes.canScroll
    }

    // MARK: - Update Subscriptions

    func subscribeToUpdates() {
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversationController = self.conversationController else { return }

                var isUserMessageInserted = false
                var itemsToReconfigure: [MessageSequenceItem] = []

                for change in changes {
                    switch change {
                    case .insert(let message, _):
                        guard message.isFromCurrentUser else { break }
                        isUserMessageInserted = true
                    case .update(let message, _):
                        guard !message.isDeleted else { break }
                        itemsToReconfigure.append(.message(messageID: message.id))
                    default:
                        break
                    }
                }

                // Once the user sends their message, we no longer need to be in the prepare state.
                if isUserMessageInserted {
                    self.dataSource.shouldPrepareToSend = false
                }

                self.dataSource.set(messagesController: conversationController,
                                    itemsToReconfigure: itemsToReconfigure,
                                    showLoadMore: self.shouldShowLoadMore)
            }.store(in: &self.subscriptions)
    }

    func scrollToMessage(with messageId: MessageId, animateScroll: Bool, animateSelection: Bool) async {
        let task = Task {
            guard let conversationController = self.conversationController else { return }

            try? await conversationController.loadNextMessages(including: messageId)

            guard !Task.isCancelled else { return }

            let messageItem: MessageSequenceItem = .message(messageID: messageId)

            guard let messageIndexPath = self.dataSource.indexPath(for: messageItem) else { return }

            let yOffset = self.collectionLayout.focusPosition(for: messageIndexPath)

            self.collectionView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: animateScroll)

            await Task.sleep(seconds: Theme.animationDurationStandard)
            
            if animateSelection, let cell = self.collectionView.cellForItem(at: messageIndexPath) {
                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = CGAffineTransform.init(scaleX: 1.05, y: 1.05)
                })
                
                await UIView.awaitAnimation(with: .fast, animations: {
                    cell.transform = .identity
                })
            }
        }
        self.scrollToMessageTask = task

        await task.value
    }

    // MARK: - Drop Zone Helpers

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.collectionLayout.getDropZoneFrame()

        return self.collectionView.convert(dropZoneFrame, to: targetView)
    }

    func getFrontmostCell() -> MessageCell? {
        return self.collectionLayout.getFrontmostCell()
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath),
              let cell = collectionView.cellForItem(at: indexPath) as? MessageCell,
              cell.content.isUserInteractionEnabled else { return }

        switch item {
        case .message(messageID: let messageID, _):
            guard let cid = self.conversation?.cid else { break }
            self.messageContentDelegate?.messageContent(cell.content, didTapMessage: (cid, messageID))
        case .loadMore, .placeholder, .initial:
            break
        }
    }
}
