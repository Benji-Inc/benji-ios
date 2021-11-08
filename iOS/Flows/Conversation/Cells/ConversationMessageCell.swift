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

/// A cell to display a high-level view of a conversation's message. Displays a limited number of recent replies to the message.
/// The user's replies and other replies are put in two stacks (along the z-axis), with the most recent reply at the front (visually obscuring the others).
class ConversationMessageCell: UICollectionViewCell, ConversationMessageCellLayoutDelegate {

    // Interaction handling
    var handleTappedMessage: ((Messageable) -> Void)?
    var handleDeleteMessage: ((Messageable) -> Void)?

    private lazy var collectionLayout = ConversationMessageCellLayout(messageDelegate: self)
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: self.collectionLayout)
        cv.keyboardDismissMode = .interactive
        return cv
    }()
    private lazy var dataSource = ConversationMessageCellDataSource(collectionView: self.collectionView)

    private var state: ConversationUIState = .read

    /// The parent message of this thread.
    var message: Messageable?

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
            guard let message = self.message else { return }
            self.handleTappedMessage?(message)
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
    func set(message: Messageable,
             replies: [Messageable],
             totalReplyCount: Int) {

        self.message = message

        // Separate the user messages from other message.
        var userReplies = replies.filter { message in
            return message.isFromCurrentUser
        }
        var otherReplies = replies.filter { message in
            return !message.isFromCurrentUser
        }
        // Put the parent message in the appropriate stack based on who sent it.
        if message.isFromCurrentUser {
            userReplies.append(message)
        } else {
            otherReplies.append(message)
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

        // Clear out the sections to make way for a fresh set of message.
        snapshot.deleteSections(ConversationMessageSection.allCases)
        snapshot.appendSections(ConversationMessageSection.allCases)

        snapshot.appendItems(otherMessages, toSection: .otherMessages)
        snapshot.appendItems(currentUserMessages, toSection: .currentUserMessages)

        self.dataSource.apply(snapshot)
    }

    func handle(isCentered: Bool) {
        UIView.animate(withDuration: 0.2) {
            if let header = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) {
                header.alpha = isCentered ? 1.0 : 0.0
            }

            if let footer = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 1)) {
                footer.alpha = isCentered ? 1.0 : 0.0
            }
        }
    }
  
    override func prepareForReuse() {
        super.prepareForReuse()

        // Remove all the items so the next message has a blank slate to work with.
        var snapshot = self.dataSource.snapshot()
        snapshot.deleteAllItems()
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Returns the frame that a message send overlay should appear based on this cells contents.
    /// The frame is in the coordinate space of the passed in view.
    func getMessageOverlayFrame(convertedTo targetView: UIView) -> CGRect {
        let userMessageCount = self.collectionView.numberOfItems(inSection: 1)
        if let frontUserCell = self.collectionView.cellForItem(at: IndexPath(item: userMessageCount - 1,
                                                                           section: 1)) {

            var overlayRect = frontUserCell.convert(frontUserCell.bounds, to: self)
            overlayRect.top += ConversationMessageCell.spaceBetweenCellTops
            return self.convert(overlayRect, to: targetView)
        }

        let otherMessageCount = self.collectionView.numberOfItems(inSection: 0)
        if let frontOtherCell = self.collectionView.cellForItem(at: IndexPath(item: otherMessageCount - 1,
                                                                            section: 0)) {

            var overlayRect = frontOtherCell.convert(frontOtherCell.bounds, to: self)
            overlayRect.top += frontOtherCell.height + ConversationMessageCell.spaceBetweenCellTops
            return self.convert(overlayRect, to: targetView)
        }

        return self.convert(CGRect(x: 0, y: 100, width: self.width, height: 50),
                            to: targetView)
    }
}

extension ConversationMessageCell: UICollectionViewDelegateFlowLayout {

    /// The space between the top of a cell and tops of adjacent cells in a stack.
    static var spaceBetweenCellTops: CGFloat { return 15 }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        var width = collectionView.width
        var height: CGFloat = MessageSubcell.minimumHeight

        // The heights of all cells in a section are the same as the front most cell in that section.
        if let messageLayout = collectionViewLayout as? ConversationMessageCellLayout,
           let latestItemIndex = messageLayout.getFrontmostItemIndexPath(inSection: indexPath.section),
           let latestItem = self.dataSource.itemIdentifier(for: latestItemIndex) {

            if let latestMessage
                = ChatClient.shared.messageController(cid: latestItem.channelID,
                                                      messageId: latestItem.messageID).message {

                height = MessageSubcell.getHeight(withWidth: width, message: latestMessage)
            }

            // Shrink down cells as they get closer to the back of the stack.
            let zIndex = messageLayout.getZIndex(forIndexPath: indexPath)
            width += CGFloat(zIndex) * 15
        }

        if self.message?.isDeleted == true {
            height = MessageSubcell.minimumHeight
        }

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        guard let messageLayout = collectionViewLayout as? ConversationMessageCellLayout else { return .zero }



        // Sections should always be tall enough to accommodate the max number of cells, regardless of
        // how many cells they actually have. If there aren't enough cells to fill that space, add section
        // insets to make up for it.
        let numberOfItems = collectionView.numberOfItems(inSection: section)

        let numberOfExtraCells = clamp(numberOfItems - 1, min: 0)
        let extraSpacersNeeded = (self.maxMessagesPerSection - 1) - numberOfExtraCells

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
            insets.bottom += CGFloat(extraSpacersNeeded) * ConversationMessageCell.spaceBetweenCellTops
        } else if section == 1 {
            // Put some space between the user's messages and non-user messages
            insets.top = Theme.contentOffset

            // Ensure that the top of the latest user reply in this cell aligns
            // with the tops of the latest user replies in adjacent cells.
            insets.top += CGFloat(extraSpacersNeeded) * ConversationMessageCell.spaceBetweenCellTops
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
        return -cellSize.height + ConversationMessageCell.spaceBetweenCellTops
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {

        // Only show a header for the first section.
        guard section == 0 else { return .zero }

        return CGSize(width: collectionView.width, height: Theme.contentOffset)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {

        // Only show a footer for the second section
        guard section == 1 else { return .zero }

        return CGSize(width: collectionView.width, height: Theme.contentOffset)
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension ConversationMessageCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { elements in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let message = self.message else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { [unowned self] action in
            self.handleDeleteMessage?(message)
        }

        let deleteMenu = UIMenu(title: "Delete Thread",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let openThread = UIAction(title: "Open Thread") { [unowned self] action in
            self.handleTappedMessage?(message)
        }

        var menuElements: [UIMenuElement] = []
        if message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }
        menuElements.append(openThread)

        return UIMenu(children: menuElements)
    }
}
