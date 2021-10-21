//
//  ReversedCollectionViewFlowLayout2.swift
//  ReversedCollectionViewFlowLayout2
//
//  Created by Martin Young on 10/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReversedCollectionViewLayout: UICollectionViewLayout {

    var itemSize = CGSize(width: 20, height: 20)
    var itemSpacing: CGFloat = 0

    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView, collectionView.frame != .zero else { return .zero }

            let contentWidth
            = collectionView.width - collectionView.contentInset.left - collectionView.contentInset.right

            let contentHeight: CGFloat
            if let firstCellAttributes = self.firstItemLayoutAttributes() {
                contentHeight = firstCellAttributes.frame.maxY
            } else {
                contentHeight = 0
            }

            return CGSize(width: contentWidth, height: contentHeight)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = self.collectionView else { return false }

        return newBounds.height != collectionView.height
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        // Clear the layout attributes cache.
        self.cellLayoutAttributes = [:]
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }

        let sectionCount = collectionView.numberOfSections
        for section in 0..<sectionCount {
            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = self.frameForItem(at: indexPath)
                self.cellLayoutAttributes[indexPath] = attributes
            }
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Return all items whose frames intersect with the given rect.
        return self.cellLayoutAttributes.values.filter { attributes in
            rect.intersects(attributes.frame)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if self.cellLayoutAttributes[indexPath] != nil {
            return self.cellLayoutAttributes[indexPath]
        }

        let frame = self.frameForItem(at: indexPath)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = frame

        return attributes
    }

    // MARK: - Layout calculations

    private func firstItemLayoutAttributes() -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        // If we don't have a first item, return nil.
        guard collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 else {
            return nil
        }

        return self.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))
    }

    private func frameForItem(at indexPath: IndexPath) -> CGRect {
        let origin = self.originForItem(at: indexPath.item)
        let size = CGSize(width: self.itemSize.width, height: self.itemSize.height)

        return CGRect(origin: origin, size: size)
    }

    private func originForItem(at index: Int) -> CGPoint {
        guard let collectionView = self.collectionView else { return .zero }

        // Get the number items above this item to determine how down the item should be pushed.
        // The lowest index will have the most items on top, and the highest index will be on the top.
        let itemsAboveCount = CGFloat(collectionView.numberOfItems(inSection: 0) - index - 1)
        let y = itemsAboveCount * (self.itemSize.height + self.itemSpacing)
        return CGPoint(x: 0, y: y)
    }
}
