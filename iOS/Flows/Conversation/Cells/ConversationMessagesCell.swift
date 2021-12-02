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

/// A cell to display a high-level view of a conversation's message. Displays a limited number of recent messages in a conversation.
/// The user's messages and other messages are put in two stacks (along the z-axis),
/// with the most recent message at the front (visually obscuring the others).
class ConversationMessagesCell: UICollectionViewCell, ConversationMessageCellLayoutDelegate {

    // Interaction handling
    var handleTappedMessage: ((ConversationMessageItem, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationMessageItem) -> Void)?

    var handleTappedConversation: ((MessageSequence) -> Void)?
    var handleDeleteConversation: ((MessageSequence) -> Void)?

    private lazy var collectionLayout = TimeMachineCollectionViewLayout()
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        cv.showsVerticalScrollIndicator = false 
        return cv
    }()
    private lazy var dataSource = ConversationMessageCellDataSource(collectionView: self.collectionView)

    private var state: ConversationUIState = .read

    /// If true, push the user messages back to prepare for a new message.
    private var prepareForSend = false

    /// The conversation containing all the messages.
    var conversation: MessageSequence?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionLayout.dataSource = self.dataSource

        self.collectionView.decelerationRate = .fast
        self.collectionView.delegate = self
        self.collectionView.set(backgroundColor: .clear)

        // Allow message subcells to scale in size without getting clipped.
        self.collectionView.clipsToBounds = false
        self.contentView.addSubview(self.collectionView)

        self.collectionView.contentInset = UIEdgeInsets(top: Theme.contentOffset,
                                                        left: 0,
                                                        bottom: 0,
                                                        right: 0)

        self.dataSource.handleTappedMessage = { [unowned self] item, content in
            self.handleTappedMessage?(item, content)
        }

        self.dataSource.handleEditMessage = { [unowned self] item in
            self.handleEditMessage?(item)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// If true we need scroll to the most recent item upon layout.
    private var needsOffsetReload = true

    override func layoutSubviews() {
        super.layoutSubviews()

        self.collectionView.expandToSuperviewSize()
        self.collectionLayout.invalidateLayout()
        self.collectionLayout.prepare()

        if self.needsOffsetReload,
           let contentOffset = self.collectionLayout.getMostRecentItemContentOffset() {

            self.collectionView.contentOffset = contentOffset
            self.collectionLayout.invalidateLayout()

            self.needsOffsetReload = false
        }
    }

    /// Configures the cell to display the given messages. The message sequence should be ordered newest to oldest.
    func set(sequence: MessageSequence) {
        self.conversation = sequence

        // Separate the user messages from other message.
        let userMessages = sequence.messages.filter { message in
            return message.isFromCurrentUser
        }

        let otherMessages = sequence.messages.filter { message in
            return !message.isFromCurrentUser
        }

        let channelID = try! ChannelId(cid: sequence.conversationId)
        // The newest message is at the bottom, so reverse the order.
        var userMessageItems = userMessages.reversed().map { message in
            return ConversationMessageItem(channelID: channelID, messageID: message.id)
        }
        if self.prepareForSend {
            userMessageItems.append(ConversationMessageItem(channelID: channelID,
                                                            messageID: "placeholderMessage"))
        }

        let otherMessageItems = otherMessages.reversed().map { message in
            return ConversationMessageItem(channelID: try! ChannelId(cid: message.conversationId),
                                           messageID: message.id)
        }

        var snapshot = self.dataSource.snapshot()

        var animateDifference = true
        if snapshot.numberOfItems == 0 {
            animateDifference = false
        }

        // Clear out the sections to make way for a fresh set of messages.
        snapshot.deleteSections(ConversationMessageSection.allCases)
        snapshot.appendSections(ConversationMessageSection.allCases)

        snapshot.appendItems(otherMessageItems, toSection: .otherMessages)
        snapshot.appendItems(userMessageItems, toSection: .currentUserMessages)

        if animateDifference {
            self.dataSource.apply(snapshot, animatingDifferences: animateDifference)
        } else {
            self.dataSource.apply(snapshot, animatingDifferences: animateDifference)
        }
    }

    func updateMessages(with event: Event) {
        var snapshot = self.dataSource.snapshot()
        switch event {
        case let event as ReactionNewEvent:
            let item = ConversationMessageItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        case let event as ReactionDeletedEvent:
            let item = ConversationMessageItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.deleteItems([item])
            }
        case let event as ReactionUpdatedEvent:
            let item = ConversationMessageItem(channelID: event.cid, messageID: event.message.id)
            if snapshot.itemIdentifiers.contains(item) {
                snapshot.reconfigureItems([item])
            }
        default:
            logDebug("event not handled")
        }

        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    func handle(isCentered: Bool) {
        guard self.collectionLayout.showMessageStatus != isCentered else { return }

        UIView.animate(withDuration: 0.2) {
            self.collectionLayout.showMessageStatus = isCentered
        }
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()

        self.needsOffsetReload = true
        self.prepareForSend = false

        // Remove all the items so the next message has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        let dropZoneFrame = self.collectionLayout.getDropZoneFrame()

        return self.collectionView.convert(dropZoneFrame, to: targetView)
    }

    func getDropZoneColor() -> Color? {
        return self.collectionLayout.getDropZoneColor()
    }

    func prepareForNewMessage() {
        self.prepareForSend = true

        guard let conversation = self.conversation else { return }
        self.set(sequence: conversation)
    }

    func unprepareForNewMessage(reloadMessages: Bool) {
        self.prepareForSend = false

        guard reloadMessages, let conversation = self.conversation else { return }
        self.set(sequence: conversation)
    }
}

extension ConversationMessagesCell: UICollectionViewDelegate {

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath),
                let cell = collectionView.cellForItem(at: indexPath) as? MessageSubcell else { return }
        
        self.handleTappedMessage?(item, cell.content)
    }
}
