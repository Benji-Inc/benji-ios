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

        // How much to scale the brightness of the background view.
        // Objects closer to the front should be brighter.
        let backgroundBrightness = 1 - CGFloat(stackIndex) * 0.05

        var backgroundColor: UIColor = indexPath.section == 0 ? .lightGray : .gray

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if backgroundColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            backgroundColor = UIColor(red: red * backgroundBrightness,
                                      green: green * backgroundBrightness,
                                      blue: blue * backgroundBrightness,
                                      alpha: alpha)
        }
        attributes.backgroundColor = backgroundColor

        // Only show text for the front most item in each section.
        attributes.shouldShowText = stackIndex == 0

        if indexPath.section == 0 {
            // The first section should have a bubble tail on its first item
            attributes.shouldShowTail = stackIndex == totalItemsInSection - 1
            attributes.bubbleTailOrientation = .up
        }

        if indexPath.section == 1 {
            // The second section should have a tail on its last item
            attributes.shouldShowTail = stackIndex == 0
            attributes.bubbleTailOrientation = .down
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
        attributes?.alpha = 1
        return attributes
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)

        if self.deletingIndexPaths.contains(itemIndexPath) {
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
