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
    var handleTappedConversation: ((MessageSequence) -> Void)?
    var handleDeleteConversation: ((MessageSequence) -> Void)?

    private lazy var collectionLayout = TimelineCollectionViewLayout()
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        return cv
    }()
    private lazy var dataSource = ConversationMessageCellDataSource(collectionView: self.collectionView)

    private var state: ConversationUIState = .read

    /// The conversation containing all the messages..
    var conversation: MessageSequence?

    /// The maximum number of messages we'll show per stack of messages.
    private let maxMessagesPerSection = 25

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

        self.dataSource.contextMenuDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// If true we need scroll to the most recent item.
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

    /// Configures the cell to display the given messages.
    func set(sequence: MessageSequence) {
        self.conversation = sequence

        // Separate the user messages from other message.
        let userMessages = sequence.messages.filter { message in
            return message.isFromCurrentUser
        }

        let otherMessages = sequence.messages.filter { message in
            return !message.isFromCurrentUser
        }

        // Only shows a limited number of messages in each stack.
        // The for the user's messages, the newest message is at the bottom, so reverse the order.
        let currentUserMessages = userMessages.prefix(self.maxMessagesPerSection).reversed().map { message in
            return ConversationMessageItem(channelID: try! ChannelId(cid: message.conversationId),
                                           messageID: message.id)
        }

        // Other messages have the newest message on top, so there's no need to reverse the messages.
        let messages = otherMessages.prefix(self.maxMessagesPerSection).reversed().map { message in
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

        snapshot.appendItems(messages, toSection: .otherMessages)
        snapshot.appendItems(currentUserMessages, toSection: .currentUserMessages)

        if animateDifference {
            self.dataSource.apply(snapshot, animatingDifferences: animateDifference)
        } else {
            self.dataSource.apply(snapshot, animatingDifferences: animateDifference)
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
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
}

extension ConversationMessagesCell: UICollectionViewDelegate {

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = self.dataSource.itemIdentifier(for: indexPath), let cell = collectionView.cellForItem(at: indexPath) as? MessageSubcell else { return }
        self.handleTappedMessage?(item, cell.content)
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ConversationMessagesCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { elements in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let conversation = self.conversation else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            self.handleDeleteConversation?(conversation)
        }


        let deleteText = conversation.isCreatedByCurrentUser ? "Delete Conversation" : "Hide Conversation"
        let deleteMenu = UIMenu(title: deleteText,
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let openConvesation = UIAction(title: "Open Conversation") { [unowned self] action in
            self.handleTappedConversation?(conversation)
        }

        var menuElements: [UIMenuElement] = []
        if conversation.isCreatedByCurrentUser {
            menuElements.append(deleteMenu)
        }
        menuElements.append(openConvesation)

        return UIMenu(children: menuElements)
    }
}
