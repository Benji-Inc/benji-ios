//
//  ReversedCollectionViewFlowLayout2.swift
//  ReversedCollectionViewFlowLayout2
//
//  Created by Martin Young on 10/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A collection view layout that lays out its content in a single column with the first item at the bottom and the last at the top.
class BottomToTopColumnCollectionViewLayout: UICollectionViewLayout {

    /// The size of the cells.
    var itemSize = CGSize(width: 20, height: 20)
    /// The size of the header
    var headerSize = CGSize(width: 20, height: 20)
    /// The vertical spacing between cells.
    var itemSpacing: CGFloat = 0

    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    private var headerLayoutAttributes: [Int : UICollectionViewLayoutAttributes] = [:]

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView, collectionView.frame != .zero else { return .zero }

            let contentHeight: CGFloat
            // The first item is the bottom-most item in the column.
            // Its max Y value is the height of thecontent.
            if let firstCellAttributes = self.firstItemLayoutAttributes() {
                contentHeight = firstCellAttributes.frame.maxY
            } else {
                contentHeight = 0
            }

            return CGSize(width: self.itemSize.width, height: contentHeight)
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
            self.headerLayoutAttributes[section]
            = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                        at: IndexPath(item: 0, section: section))


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
        let itemAttributes = self.cellLayoutAttributes.values.filter { attributes in
            return rect.intersects(attributes.frame)
        }
        let headerAttributes = self.headerLayoutAttributes.values.filter { attributes in
            return rect.intersects(attributes.frame)
        }

        return itemAttributes + headerAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.cellLayoutAttributes[indexPath]  {
            return attributes
        }

        let frame = self.frameForItem(at: indexPath)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = frame

        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        // Returned the cached attributes if we've already calculated these attributes
        if let attributes = self.headerLayoutAttributes[indexPath.section] {
            return attributes
        }

        let frame = self.frameForHeaderSupplementaryView(inSection: indexPath.section)
        let attributes
        = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                           with: indexPath)
        attributes.frame = frame

        return attributes
    }

    // MARK: - Item Layout Calculations

    /// Get the layout attributes for the first item in the collection. This should be the bottom most item.
    private func firstItemLayoutAttributes() -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        // If we don't have a first item, return nil.
        guard collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 else {
            return nil
        }

        return self.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))
    }

    /// Gets the frame rect for the item at the given index.
    private func frameForItem(at indexPath: IndexPath) -> CGRect {
        let origin = self.originForItem(at: indexPath)
        let size = CGSize(width: self.itemSize.width, height: self.itemSize.height)

        return CGRect(origin: origin, size: size)
    }

    /// Gets the top left corner position for the item at the given index path.
    private func originForItem(at index: IndexPath) -> CGPoint {
        guard let collectionView = self.collectionView else { return .zero }

        // Get the height of all the sections above this one.
        var heightOfPreviousSections: CGFloat = 0
        for sectionIndex in index.section..<collectionView.numberOfSections {
            heightOfPreviousSections += self.heightOfSection(sectionIndex)
        }

        // Get the number items above this item to determine how far down the item should be pushed.
        // The lowest index will have the most items on top, and the highest index will be on the top.
        let itemsAboveCount = CGFloat(collectionView.numberOfItems(inSection: 0) - index.item - 1)
        let headerSpace = self.headerSize.height + self.itemSpacing
        let y = itemsAboveCount * (self.itemSize.height + self.itemSpacing) + headerSpace
        return CGPoint(x: 0, y: y)
    }

    /// Returns the height of the section at the given index.
    private func heightOfSection(_ section: Int) -> CGFloat {
        guard let collectionView = self.collectionView else { return 0 }

        let numberInSection = CGFloat(collectionView.numberOfItems(inSection: section))
        let headerSpace = self.headerSize.height + self.itemSpacing
        return (self.itemSpacing + self.itemSize.height) * numberInSection + headerSpace
    }

    // MARK: - Header Layout Calculations

    /// Gets the frame rect for a header.
    private func frameForHeaderSupplementaryView(inSection section: Int) -> CGRect {
        let origin = self.originForHeader(at: section)
        let size = CGSize(width: self.headerSize.width, height: self.headerSize.height)

        return CGRect(origin: origin, size: size)
    }

    /// Gets the top left corner position for the header in the given section.
    private func originForHeader(at index: Int) -> CGPoint {
        guard let collectionView = self.collectionView else { return .zero }

        // Get the height of all the sections above this one.
        var heightOfPreviousSections: CGFloat = 0
        for sectionIndex in index+1..<collectionView.numberOfSections {
            heightOfPreviousSections += self.heightOfSection(sectionIndex)
        }

        return CGPoint(x: 0, y: heightOfPreviousSections)
    }

}
