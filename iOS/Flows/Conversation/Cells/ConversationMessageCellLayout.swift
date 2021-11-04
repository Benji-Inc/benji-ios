//
//  ConversationMessageCellLayout.swift
//  Jibber
//
//  Created by Martin Young on 11/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationMessageCellLayout: UICollectionViewFlowLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }

    override init() {
        super.init()
        self.scrollDirection = .vertical
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.scrollDirection = .vertical
    }

    var messageController: MessageController?

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesInRect = super.layoutAttributesForElements(in: rect) else { return nil }

        for attributes in attributesInRect {
            guard let messageAttributes = attributes as? ConversationMessageCellLayoutAttributes else {
                continue
            }
            self.update(attributes: messageAttributes)
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

    private func update(attributes: ConversationMessageCellLayoutAttributes) {
        guard let collectionView = self.collectionView else { return }

        let indexPath = attributes.indexPath
        let totalItemsInSection = collectionView.numberOfItems(inSection: indexPath.section)

        // The higher the cell's index, the closer it is to the front of the message stack.
        let stackIndex = totalItemsInSection - indexPath.item - 1

        // Only show text for the front most item in each section.
        attributes.shouldShowText = stackIndex == 0

        // Objects closer to the front of the stack should be brighter.
        let backgroundBrightness = 1 - CGFloat(stackIndex) * 0.05
        var backgroundColor: UIColor = indexPath.section == 0 ? .lightGray : .gray
        backgroundColor = backgroundColor.color(withBrightness: backgroundBrightness)

        attributes.backgroundColor = backgroundColor

        var isMostRecentMessageFromUser = false
        if let message = self.messageController?.message?.latestReplies.first {
            isMostRecentMessageFromUser = message.isFromCurrentUser
        }

        if indexPath.section == 0 {
            // The first section should have a bubble tail on its first item
            attributes.shouldShowTail = stackIndex == totalItemsInSection - 1
            attributes.bubbleTailOrientation = .up

            // If the most recent message is from the other user, then highlight it with a white background.
            if !isMostRecentMessageFromUser && stackIndex == 0 {
                attributes.backgroundColor = .white
            }
        }

        if indexPath.section == 1 {
            // The second section should have a tail on its last item
            attributes.shouldShowTail = stackIndex == 0
            attributes.bubbleTailOrientation = .down

            // If the most recent message is from the current user, then highlight it with a white background.
            if isMostRecentMessageFromUser && stackIndex == 0 {
                attributes.backgroundColor = .white
            }
        }
    }

    // MARK: - Custom Animations

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
