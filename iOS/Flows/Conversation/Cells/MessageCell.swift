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



/// A cell to display a message along with a limited number of replies to that message.
/// The root message and replies are stacked along the z-axis, with the most recent reply at the front (visually obscuring the others).
class MessageCell: UICollectionViewCell {

    // Interaction handling
    var handleTappedMessage: ((Messageable) -> Void)?
    var handleDeleteMessage: ((Messageable) -> Void)?
    private lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.keyboardDismissMode = .interactive
        return cv
    }()
    private let cellRegistration = UICollectionView.CellRegistration<MessageSubcell, Messageable>
    { (cell, indexPath, item) in
        cell.setText(with: item)
    }

    private let headerRegistration
    = UICollectionView.SupplementaryRegistration<TimeSentView>(elementKind: UICollectionView.elementKindSectionHeader) { supplementaryView, elementKind, indexPath in
    }

    private var state: ConversationUIState = .read

    /// The root message to display.
    private var message: Messageable?
    /// A subset of replies to the root message that we want to display. The count is no more than the maxShownReplies.
    private var replies: [Messageable] = []
    /// The maximum number of replies we'll show.
    private let maxShownReplies = 2
    /// The total number of replies to the root message. This may be more than the number of replies displayed.
    private var totalReplyCount: Int = 0

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
    func set(message: Messageable, replies: [Messageable], totalReplyCount: Int) {
        self.message = message
        self.replies = replies.prefix(self.maxShownReplies).reversed()
        self.totalReplyCount = totalReplyCount

        self.collectionView.reloadData()
    }

    func handle(isCentered: Bool) { }
}

extension MessageCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    /// The space between the top of a cell and tops of adjacent cells.
    var spaceBetweenCellTops: CGFloat { return 15 }
    /// The height of each message subcell
    var cellHeight: CGFloat {
        guard let msg = self.message as? ChatMessage, msg.type != .reply else {
            return self.collectionView.height
        }
        // Cell height should allow for one base message, plus the max number of replies to fit vertically.
        let height = (self.collectionView.height * 0.33) - self.spaceBetweenCellTops * CGFloat(self.maxShownReplies)
        return clamp(height, min: 1)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard self.message.exists else { return 0 }
        // Add 1 to account for the base message.
        return self.replies.count + 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let message: Messageable?
        // The first item is always the base message.
        if indexPath.item == 0 {
            message = self.message
        } else {
            message = self.replies[safe: indexPath.item - 1]
        }

        guard let message = message else { return UICollectionViewCell() }

        let cell = collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration,
                                                                for: indexPath,
                                                                item: message)

        let totalCells = self.collectionView(collectionView, numberOfItemsInSection: indexPath.section)

        // The higher the cells index, the closer it is to the front of the message stack.
        let stackIndex = totalCells - indexPath.item - 1
        cell.configureBackground(withStackIndex: stackIndex, message: message)

        // Only show the reply count on the top cell in the stack, and only if there is more than one reply.
        if stackIndex == 0 && self.totalReplyCount > 1 {
            cell.setReplyCount(self.totalReplyCount)
        } else {
            cell.setReplyCount(nil)
        }

        // The menu interaction should only be on the front most cell,
        // and only if the user created the original message.
        if stackIndex == 0 {
            cell.backgroundColorView.addInteraction(self.contextMenuInteraction)
        } else {
            cell.backgroundColorView.interactions.removeAll()
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
            
            if let latestMessage = self.replies.last {
                header.configure(with: latestMessage)
            } else if let message = self.message {
                header.configure(with: message)
            }
            return header
        case UICollectionView.elementKindSectionFooter:
            return UICollectionReusableView()
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.width, height: 30)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width = collectionView.width
        return CGSize(width: width, height: self.cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        // Return a negative spacing so that the cells overlap.
        return -self.cellHeight + self.spaceBetweenCellTops
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension MessageCell: UIContextMenuInteractionDelegate {

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
