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
    var handleTappedMessage: ((MessageSequenceItem, MessageContentView) -> Void)?
    var handleEditMessage: ((MessageSequenceItem) -> Void)?

    var handleTappedConversation: ((MessageSequence) -> Void)?
    var handleDeleteConversation: ((MessageSequence) -> Void)?

    private lazy var collectionLayout = MessagesTimeMachineCollectionViewLayout()
    lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        cv.showsVerticalScrollIndicator = false 
        return cv
    }()
    private lazy var dataSource = MessageSequenceCollectionViewDataSource(collectionView: self.collectionView)

    /// If true we should scroll to the last item in the collection in layout subviews.
    private var scrollToLastItemOnLayout: Bool = false

    private var state: ConversationUIState = .read

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

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionLayout.dataSource = self.dataSource

        self.collectionView.decelerationRate = .fast
        self.collectionView.set(backgroundColor: .clear)

        // Allow message subcells to scale in size without getting clipped.
        self.collectionView.clipsToBounds = false
        self.contentView.addSubview(self.collectionView)

        self.dataSource.handleTappedMessage = { [unowned self] item, content in
            self.handleTappedMessage?(item, content)
        }

        self.dataSource.handleEditMessage = { [unowned self] item in
            self.handleEditMessage?(item)
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] cid in
            Task {
                self.conversationController?.loadPreviousMessages()
            }
        }
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

    /// Configures the cell to display the given messages. The message sequence should be ordered newest to oldest.
    func set(conversation: Conversation) {
        // Create a new conversation controller if this is a different conversation than before.
        if conversation.cid != self.conversation?.cid {
            self.conversationController = ChatClient.shared.channelController(for: conversation.cid)
            self.subscribeToUpdates()
        }

        // Scroll to the last item when a new conversation is loaded.
        if self.dataSource.snapshot().itemIdentifiers.isEmpty {
            self.scrollToLastItemOnLayout = true
            self.setNeedsLayout()
        }

        self.dataSource.set(messageSequence: conversation, showLoadMore: self.shouldShowLoadMore)
    }

    func set(layoutForDropZone: Bool) {
        self.collectionLayout.layoutForDropZone = layoutForDropZone
    }

    func set(isPreparedToSend: Bool) {
        self.dataSource.shouldPrepareToSend = isPreparedToSend
    }

    func updateMessages(with event: Event) {
        var snapshot = self.dataSource.snapshot()
        switch event {
        case let event as ReactionNewEvent:
            let item = MessageSequenceItem.message(cid: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        case let event as ReactionDeletedEvent:
            let item = MessageSequenceItem.message(cid: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.deleteItems([item])
            }
        case let event as ReactionUpdatedEvent:
            let item = MessageSequenceItem.message(cid: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        default:
            logDebug("event not handled")
        }

        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()

        self.dataSource.shouldPrepareToSend = false

        self.subscriptions.removeAll()

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

    func getDropZoneColor() -> Color? {
        return self.collectionLayout.getDropZoneColor()
    }

    func getBottomFrontMostCell() -> MessageSubcell? {
        return self.collectionLayout.getBottomFrontMostCell()
    }
}
