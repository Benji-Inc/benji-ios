//
//  ConversationMessageCellLayout.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol ConversationMessageCellLayoutDelegate: AnyObject {
    var conversation: Messageable? { get }
}

/// A custom collectionview layout for conversation message cells. This class assumes the collection view contains
/// MessageSubcell cells laid out in two separate stacks along the z-axis.
class ConversationMessagesCellLayout: UICollectionViewFlowLayout {

    /// If true, the time sent decoration views should be displayed.
    var showMessageStatus: Bool = false {
        didSet { self.invalidateLayout() }
    }
    unowned let conversationDelegate: ConversationMessageCellLayoutDelegate

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }

    init(conversationDelegate: ConversationMessageCellLayoutDelegate) {
        self.conversationDelegate = conversationDelegate

        super.init()

        self.scrollDirection = .vertical
        self.register(MessageStatusView.self, forDecorationViewOfKind: MessageStatusView.objectIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributesInRect = super.layoutAttributesForElements(in: rect) else { return nil }

        for attributes in attributesInRect {
            guard let messageAttributes = attributes as? ConversationMessageCellLayoutAttributes else {
                continue
            }
            self.update(attributes: messageAttributes)
        }

        let sectionCount = self.collectionView?.numberOfSections ?? 0
        for sectionIndex in 0..<sectionCount {
            let decorationAttributes
            = self.layoutAttributesForDecorationView(ofKind: MessageStatusView.objectIdentifier,
                                                     at: IndexPath(item: 0,
                                                                   section: sectionIndex))
            if let decorationAttributes = decorationAttributes {
                attributesInRect.append(decorationAttributes)
            }
        }

        return attributesInRect
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)

        if let messageAttributes = attributes as? ConversationMessageCellLayoutAttributes {
            self.update(attributes: messageAttributes)
        }

        return attributes
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                    at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        guard let frontmostItemIndex = self.getFrontmostItemIndexPath(inSection: indexPath.section),
              let frontmostAttributes = self.layoutAttributesForItem(at: frontmostItemIndex) else {
                  return nil
              }

        let attributes
        = MessageStatusViewLayoutAttributes(forDecorationViewOfKind: MessageStatusView.objectIdentifier,
                                            with: indexPath)

        if indexPath.section == 0 {
            // Position the decoration above the frontmost item in the first section
            attributes.frame = CGRect(x: frontmostAttributes.frame.left,
                                      y: frontmostAttributes.frame.top - Theme.contentOffset + 7,
                                      width: frontmostAttributes.frame.width,
                                      height: Theme.contentOffset)
        } else {
            // Position the decoration below the frontmost item in the second section
            attributes.frame = CGRect(x: frontmostAttributes.frame.left,
                                      y: frontmostAttributes.frame.bottom - 7,
                                      width: frontmostAttributes.frame.width,
                                      height: Theme.contentOffset)
        }

        guard let conversation = self.conversationDelegate.conversation else { return nil }

        let cid = try! ChannelId(cid: conversation.conversationId)
        let conversationController = ChatClient.shared.channelController(for: cid)
        let mostRecentMessage
        = conversationController.getMostRecentMessage(fromCurrentUser: indexPath.section == 1)


        if let read = conversationController.conversation.reads.first(where: { read in
            return read.user == mostRecentMessage?.author
        }), let message = mostRecentMessage {
            attributes.status = ChatMessageStatus(read: read, message: message)
        }

        attributes.alpha = self.showMessageStatus ? 1 : 0

        return attributes
    }

    // MARK: - Attribute Modifications

    private func update(attributes: ConversationMessageCellLayoutAttributes) {
        let indexPath = attributes.indexPath

        let zIndex = self.getZIndex(forIndexPath: indexPath)

        attributes.zIndex = zIndex

        // Only show text for the front most item in each section.
        attributes.shouldShowText = zIndex == 0

        // Objects closer to the front of the stack should be brighter.
        let backgroundBrightness = 1 + CGFloat(zIndex) * 0.05
        var backgroundColor: UIColor = indexPath.section == 0 ? .lightGray : .gray
        backgroundColor = backgroundColor.color(withBrightness: backgroundBrightness)

        // Set the cell background color. The color may be overwritten if this is the most recent message.
        attributes.backgroundColor = backgroundColor

        var isMostRecentMessageFromUser = false
        if let mostRecentMessage = self.conversationDelegate.conversation?.mostRecentMessage {
            isMostRecentMessageFromUser = mostRecentMessage.isFromCurrentUser
        }

        // Each section should have a tail only on its frontmost item.
        attributes.shouldShowTail = zIndex == 0

        if indexPath.section == 0 {
            attributes.bubbleTailOrientation = .up

            // If the most recent message is from the other user, then highlight it with a white background.
            if !isMostRecentMessageFromUser && zIndex == 0 {
                attributes.backgroundColor = .white
            }
        }

        if indexPath.section == 1 {
            attributes.bubbleTailOrientation = .down

            // If the most recent message is from the current user, then highlight it with a white background.
            if isMostRecentMessageFromUser && zIndex == 0 {
                attributes.backgroundColor = .white
            }
        }
    }

    // MARK: - Helper Functions

    /// Returns the z index of the cell at the specified index path.
    /// The frontmost item in a section will always have a z-index of 0. Items further back will have negative indices.
    func getZIndex(forIndexPath indexPath: IndexPath) -> Int {
        guard let collectionView = self.collectionView else { return 0 }

        let totalItemsInSection = collectionView.numberOfItems(inSection: indexPath.section)

        if indexPath.section == 0 {
            // In the first section, the frontmost item is the first one.
            return -indexPath.item
        } else if indexPath.section == 1 {
            // In the second section, the frontmost item is the last one.
            return -(totalItemsInSection - indexPath.item - 1)
        } else {
            // If we add more than two sections, the frontmost item is undetermined.
            return 0
        }
    }

    /// Returns the index path of the item with the highest z-index value in the specified section.
    func getFrontmostItemIndexPath(inSection section: Int) -> IndexPath? {
        guard let collectionView = self.collectionView else { return nil }

        let totalItemsInSection = collectionView.numberOfItems(inSection: section)

        for i in 0..<totalItemsInSection {
            let indexPath = IndexPath(item: i, section: section)
            if self.getZIndex(forIndexPath: indexPath) == 0 {
                return indexPath
            }
        }

        return nil
    }

    // MARK: - Custom Diff Animations

    private var insertingIndexPaths: [IndexPath] = []
    private var deletingIndexPaths: [IndexPath] = []

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        self.insertingIndexPaths.removeAll()
        self.deletingIndexPaths.removeAll()

        for update in updateItems {
            if let indexPath = update.indexPathBeforeUpdate, update.updateAction == .delete {
                self.deletingIndexPaths.append(indexPath)
            }

            if let indexPath = update.indexPathAfterUpdate, update.updateAction == .insert {
                self.insertingIndexPaths.append(indexPath)
            }
        }
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        // Because the user is dropping the message directly on the stack,
        // the message should appear immediately, not fade in.
        attributes?.alpha = 1
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)

        if self.deletingIndexPaths.contains(itemIndexPath) {
            // Shrink down the message we're deleting. This is also prevents the deleted cell from
            // covering other views that are moving to take its place.
            attributes?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }

        return attributes
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.insertingIndexPaths.removeAll()
        self.deletingIndexPaths.removeAll()
    }
}
