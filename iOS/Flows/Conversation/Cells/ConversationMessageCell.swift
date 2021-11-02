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
class ConversationMessageCell: UICollectionViewCell {

    // Interaction handling
    var handleTappedMessage: ((Messageable) -> Void)?
    var handleDeleteMessage: ((Messageable) -> Void)?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.keyboardDismissMode = .interactive
        return cv
    }()

    // Cell/Header/Footer registration
    private let cellRegistration = UICollectionView.CellRegistration<MessageSubcell, Messageable>
    { (cell, indexPath, item) in
        cell.setText(with: item)
    }
    private let headerRegistration
    = UICollectionView.SupplementaryRegistration<TimeSentView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
    }
    private let footerRegistration
    = UICollectionView.SupplementaryRegistration<TimeSentView>(elementKind: UICollectionView.elementKindSectionFooter) { supplementaryView, elementKind, indexPath in
    }

    private var state: ConversationUIState = .read

    /// The parent message of this thread.
    private var message: Messageable?
    /// The current user's replies to the root message that we want to display. May include the root message.
    private var currentUserMessages: [Messageable] = []
    /// Other people's replies to the root message that we want to display. May include the root message.
    private var otherMessages: [Messageable] = []

    /// The maximum number of replies we'll show per stack of messages.
    private let maxShownRepliesPerStack = 3

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.collectionView.dataSource = self
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
        // The newest messages are stacked on top, so reverse the order.
        self.currentUserMessages = userReplies.prefix(self.maxShownRepliesPerStack).reversed()
        self.otherMessages = otherReplies.prefix(self.maxShownRepliesPerStack).reversed()

        self.collectionView.reloadData()
    }

    func handle(isCentered: Bool) { }

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

extension ConversationMessageCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// The space between the top of a cell and tops of adjacent cells in a stack.
    static var spaceBetweenCellTops: CGFloat { return 15 }

    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // There are always two sections:
        // One for the other people's replies and another for the current user's replies.
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var itemCount = 0

        // The first section contains replies from other users.
        if section == 0 {
            itemCount = self.otherMessages.count
        } else if section == 1 {
            // The second section contains replies from the current user.
            itemCount = self.currentUserMessages.count
        }

        return itemCount
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        var message: Messageable? = nil
        if indexPath.section == 0 {
            message = self.otherMessages[safe: indexPath.item]
        } else if indexPath.section == 1 {
            message = self.currentUserMessages[safe: indexPath.item]
        }

        guard let message = message else { return UICollectionViewCell() }

        let cell = collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration,
                                                                for: indexPath,
                                                                item: message)

        let totalCells = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)

        // The higher the cells index, the closer it is to the front of the message stack.
        let stackIndex = totalCells - indexPath.item - 1

        let showBubbleTail: Bool
        if message.isFromCurrentUser {
            // Only show a speech bubble tail for the front-most user reply.
            showBubbleTail = stackIndex == 0
        } else {
            // Only show a speech bubble tail for the back-most reply from other users.
            showBubbleTail = indexPath.item == 0
        }

        cell.configureBackground(withStackIndex: stackIndex,
                                 message: message,
                                 showBubbleTail: showBubbleTail)

        // The menu interaction should only be on the front most cell,
        // and only if the user created the original message.
        cell.backgroundColorView.interactions.removeAll()
        if stackIndex == 0 {
            let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
            cell.backgroundColorView.addInteraction(contextMenuInteraction)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header
            = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerRegistration,
                                                                    for: indexPath)
            let latestMessage = self.otherMessages.last
            header.configure(with: latestMessage)
            return header
        case UICollectionView.elementKindSectionFooter:
            let footer
            = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerRegistration,
                                                                    for: indexPath)
            let latestMessage = self.currentUserMessages.last
            footer.configure(with: latestMessage)
            return footer
        default:
            return UICollectionReusableView()
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.width
        var height: CGFloat = 50

        // The heights of all cells in a section are the same as the front most cell in that section.
        switch indexPath.section {
        case 0:
            guard let latestMessage = self.otherMessages.last else { break }
            height = MessageSubcell.getHeight(withWidth: width, message: latestMessage)
        case 1:
            guard let latestMessage = self.currentUserMessages.last else { break }
            height = MessageSubcell.getHeight(withWidth: width, message: latestMessage)
        default:
            break
        }

        if self.message?.isDeleted == true {
            height = 50
        }

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {

        var insets: UIEdgeInsets = .zero
        // Put a little space between the different reply sections.
        if section == 1 {
            insets.top = Theme.contentOffset

            // Ensure that current user replies align with other user replies in adjacent cells.
            if collectionView.numberOfItems(inSection: 0) == 0 {
                insets.top += MessageSubcell.bubbleTailLength
            }
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
        // Only show a header for the first section
        if section == 0 && !self.otherMessages.isEmpty {
            return CGSize(width: collectionView.width, height: Theme.contentOffset)
        }

        return .zero
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        // Only show a header for the second section
        if section == 1 && !self.currentUserMessages.isEmpty {
            return CGSize(width: collectionView.width, height: Theme.contentOffset)
        }

        return .zero
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
