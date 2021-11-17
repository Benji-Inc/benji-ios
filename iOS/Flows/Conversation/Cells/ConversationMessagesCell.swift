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
    var handleTappedConversation: ((Messageable) -> Void)?
    var handleDeleteConversation: ((Messageable) -> Void)?

    private lazy var collectionLayout = ConversationMessagesCellLayout(conversationDelegate: self)
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        return cv
    }()
    private lazy var dataSource = ConversationMessageCellDataSource(collectionView: self.collectionView)

    private var state: ConversationUIState = .read

    /// The conversation containing all the messages..
    var conversation: Messageable?

    /// The maximum number of messages we'll show per stack of messages.
    private let maxMessagesPerSection = 3

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionView.delegate = self
        self.collectionView.set(backgroundColor: .clear)
        self.contentView.addSubview(self.collectionView)
        self.collectionView.contentInset = UIEdgeInsets(top: Theme.contentOffset,
                                                        left: 0,
                                                        bottom: 0,
                                                        right: 0)

        self.collectionView.onTap { [unowned self] tapRecognizer in
            guard let conversation = self.conversation else { return }
            self.handleTappedConversation?(conversation)
        }

        self.dataSource.contextMenuDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Let the collection view know we're about to invalidate the layout so there aren't item size
        // conflicts.
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.expandToSuperviewSize()
    }

    /// Configures the cell to display the given messages.
    ///
    /// - Parameters:
    ///     - message: The root message to display, which may have replies.
    ///     - replies: The currently loaded replies to the message. These should be ordered by newest to oldest.
    ///     - totalReplyCount: The total number of replies that this message has. It may be more than the passed in replies.
    func set(message: Messageable?,
             replies: [Messageable],
             totalReplyCount: Int) {

        self.conversation = message

        // Separate the user messages from other message.
        var userReplies = replies.filter { message in
            return message.isFromCurrentUser
        }
        var otherReplies = replies.filter { message in
            return !message.isFromCurrentUser
        }
        // Put the parent message in the appropriate stack based on who sent it.
        if let message = message {
            if message.isFromCurrentUser {
                userReplies.append(message)
            } else {
                otherReplies.append(message)
            }
        }

        // Only shows a limited number of messages in each stack.
        // The for the user's messages, the newest message is at the bottom, so reverse the order.
        let currentUserMessages = userReplies.prefix(self.maxMessagesPerSection).reversed().map { message in
            return ConversationMessageItem(channelID: try! ChannelId(cid: message.conversationId),
                                           messageID: message.id)
        }

        // Other messages have the newest message on top, so there's no need to reverse the messages.
        let otherMessages = otherReplies.prefix(self.maxMessagesPerSection).map { message in
            return ConversationMessageItem(channelID: try! ChannelId(cid: message.conversationId),
                                           messageID: message.id)
        }
        var snapshot = self.dataSource.snapshot()

        // Clear out the sections to make way for a fresh set of messages.
        snapshot.deleteSections(ConversationMessageSection.allCases)
        snapshot.appendSections(ConversationMessageSection.allCases)

        snapshot.appendItems(otherMessages, toSection: .otherMessages)
        snapshot.appendItems(currentUserMessages, toSection: .currentUserMessages)

        self.dataSource.apply(snapshot)
    }

    func handle(isCentered: Bool) {
        guard self.collectionLayout.showMessageStatus != isCentered else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.collectionLayout.showMessageStatus = isCentered
        }
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()

        // Remove all the items so the next message has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Returns the frame that a message drop zone should have, based on this cell's contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageDropZoneFrame(convertedTo targetView: UIView) -> CGRect {
        if let frontCellIndex = self.collectionLayout
            .getFrontmostItemIndexPath(inSection: ConversationMessageSection.currentUserMessages.rawValue),
           let frontUserCell = self.collectionView.cellForItem(at: frontCellIndex) {

            let overlayRect = frontUserCell.convert(frontUserCell.bounds, to: self)
            return self.convert(overlayRect, to: targetView)
        }

        return self.convert(CGRect(x: 0,
                                   y: MessageSubcell.maximumHeight
                                   + ConversationMessagesCell.spaceBetweenCellTops * CGFloat(self.maxMessagesPerSection) * 2
                                   + Theme.contentOffset,
                                   width: self.width,
                                   height: MessageSubcell.minimumHeight),
                            to: targetView)
    }
}

extension ConversationMessagesCell: UICollectionViewDelegateFlowLayout {

    /// The space between the top of a cell and tops of adjacent cells in a stack.
    static var spaceBetweenCellTops: CGFloat { return 8 }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logDebug("\(indexPath)")
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let messageLayout = collectionViewLayout as? ConversationMessagesCellLayout else { return .zero }

        var width = collectionView.width
        var height: CGFloat = MessageSubcell.minimumHeight

        // The heights of all cells in a section are the same as the front most cell in that section.
        if let frontmostItemIndex = messageLayout.getFrontmostItemIndexPath(inSection: indexPath.section),
           let frontmostItem = self.dataSource.itemIdentifier(for: frontmostItemIndex) {

            // The height of the frontmost item depends on the content of the message it displays.
            if let frontmostMessage
                = ChatClient.shared.messageController(cid: frontmostItem.channelID,
                                                      messageId: frontmostItem.messageID).message {

                height = MessageSubcell.getHeight(withWidth: width, message: frontmostMessage)
            }
        }

        // Shrink down cells widths the farther back they are in the stack.
        let zIndex = messageLayout.getZIndex(forIndexPath: indexPath)
        width += CGFloat(zIndex) * 15

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        guard let messageLayout = collectionViewLayout as? ConversationMessagesCellLayout else { return .zero }

        // Sections are a fixed height. They are exactly tall enough to accommodate the maximum cell count
        // per section with the frontmost cell at the maximum height.
        // If the existing cells aren't enough that match that height, we add section
        // insets to make up the difference.

        let numberOfItems = collectionView.numberOfItems(inSection: section)
        // The number of cells behind the frontmost cells.
        let numberOfCoveredCells = clamp(numberOfItems - 1, min: 0)
        // The amount of extra space units we need to add to the insets to ensure a fixed section height.
        let extraSpacersNeeded
        = (self.maxMessagesPerSection - 1) - numberOfCoveredCells

        // The following code ensures that:
        // 1. Sections are fixed height.
        // 2. Frontmost non-user messages have their bottoms aligned across ConversationMessageCells.
        // 3. Frontmost user messages have their tops aligned across ConversationMessageCells.
        var insets: UIEdgeInsets = .zero
        if section == 0 {
            if let frontMostIndex = messageLayout.getFrontmostItemIndexPath(inSection: section) {
                let frontmostItemHeight = self.collectionView(collectionView,
                                                              layout: collectionViewLayout,
                                                              sizeForItemAt: frontMostIndex).height
                insets.top = MessageSubcell.maximumHeight - frontmostItemHeight
            } else {
                insets.top = MessageSubcell.maximumHeight
            }

            // Ensure that the bottom of the latest non-user reply in this cell aligns
            // with the bottom of the latest non-user reply in adjacent cells.
            insets.bottom += CGFloat(extraSpacersNeeded) * ConversationMessagesCell.spaceBetweenCellTops
        } else if section == 1 {
            // Put some space between the two sections of messages.
            insets.top = Theme.contentOffset.half

            // Ensure that the top of the latest user reply in this cell aligns
            // with the tops of the latest user replies in adjacent cells.
            insets.top += CGFloat(extraSpacersNeeded) * ConversationMessagesCell.spaceBetweenCellTops
        }

        return insets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        let cellSize = self.collectionView(collectionView,
                                           layout: collectionViewLayout,
                                           sizeForItemAt: IndexPath(item: 0, section: section))
        // Return a negative spacing so that the cells overlap.
        return -cellSize.height + ConversationMessagesCell.spaceBetweenCellTops
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
        guard let message = self.conversation else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            self.handleDeleteConversation?(message)
        }

        let deleteMenu = UIMenu(title: "Delete Thread",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let openThread = UIAction(title: "Open Thread") { [unowned self] action in
            self.handleTappedConversation?(message)
        }

        var menuElements: [UIMenuElement] = []
        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }
        menuElements.append(openThread)

        return UIMenu(children: menuElements)
    }
}
