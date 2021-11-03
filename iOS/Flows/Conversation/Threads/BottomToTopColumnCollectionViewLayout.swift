//
//  ReversedCollectionViewFlowLayout2.swift
//  ReversedCollectionViewFlowLayout2
//
//  Created by Martin Young on 10/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol BottomToTopColumnCollectionViewLayoutDelegate: AnyObject {
    func bottomToTopColumnLayout(_ layout: BottomToTopColumnCollectionViewLayout,
                                 itemSizeForItemAtIndexPath indexPath: IndexPath) -> CGSize
}

/// A collection view layout that lays out its content in a single column with the first item at the bottom and the last at the top.
class BottomToTopColumnCollectionViewLayout: UICollectionViewLayout {

    /// The default size of the cells. This is ignored if a delegate is assigned.
    var itemSize = CGSize(width: 20, height: 20)
    /// The size of the header.
    var headerSize = CGSize(width: 20, height: 20)
    /// The vertical spacing between cells.
    var itemSpacing: CGFloat = 0

    weak var delegate: BottomToTopColumnCollectionViewLayoutDelegate?

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

            return CGSize(width: 1, height: contentHeight)
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
        for section in (0..<sectionCount).reversed() {
            // Calculate and cache all of the header layout attributes
            self.headerLayoutAttributes[section]
            = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                        at: IndexPath(item: 0, section: section))


            let itemCount = collectionView.numberOfItems(inSection: section)
            for item in (0..<itemCount).reversed() {
                let indexPath = IndexPath(item: item, section: section)
                // Calculate and cache the layout attributes for the items in each section.
                self.cellLayoutAttributes[indexPath] = self.layoutAttributesForItem(at: indexPath)
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

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        if let itemAboveFrame = self.frameForItemOrHeader(aboveItemAt: indexPath) {
            attributes.frame.origin = CGPoint(x: 0, y: itemAboveFrame.bottom + self.itemSpacing)
        } else {
            attributes.frame.origin = .zero
        }

        attributes.frame.size = self.sizeForItem(at: indexPath)

        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        guard self.headerSize != .zero else { return nil }

        // Returned the cached attributes if we've already calculated these attributes
        if let attributes = self.headerLayoutAttributes[indexPath.section] {
            return attributes
        }

        let attributes
        = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                           with: indexPath)

        if let itemAboveFrame = self.frameForItemOrHeader(aboveHeaderInSection: indexPath.section) {
            attributes.frame.origin = CGPoint(x: 0, y: itemAboveFrame.bottom + self.itemSpacing)
        } else {
            attributes.frame = .zero
        }

        attributes.frame.size = self.headerSize

        return attributes
    }

    private func frameForItemOrHeader(aboveItemAt indexPath: IndexPath) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }

        let isTopSection = indexPath.section == collectionView.numberOfSections - 1
        let isTopItemInSection
        = indexPath.item == collectionView.numberOfItems(inSection: indexPath.section) - 1


        if isTopItemInSection {
            if let headerAboveAttributes
            = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                        at: IndexPath(item: 0, section: indexPath.section)) {

                return headerAboveAttributes.frame
            }

            if !isTopSection,
                let itemAboveAttributes
                = self.layoutAttributesForItem(at: IndexPath(item: 0, section: indexPath.section + 1)) {

                return itemAboveAttributes.frame
            }

            return nil
        }


        if let itemAboveAttributes = self.layoutAttributesForItem(at: IndexPath(item: indexPath.item + 1,
                                                                                section: indexPath.section)) {
            return itemAboveAttributes.frame
        }

        return nil
    }

    private func frameForItemOrHeader(aboveHeaderInSection section: Int) -> CGRect? {
        guard let collectionView = self.collectionView else { return nil }

        let isTopSection = section == collectionView.numberOfSections - 1

        // If this is the top section, there's nothing above this header.
        if isTopSection {
            return nil
        }


        // Try to get the bottom most item in the section directly above us.
        if let itemAboveAttributes = self.layoutAttributesForItem(at: IndexPath(item: 0,
                                                                                section: section + 1)) {
            return itemAboveAttributes.frame
        }

        // If there was no item above, see if there's a header in the section above us.
        if let headerAboveAttributes
            = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                        at: IndexPath(item: 0, section: section + 1)) {
                return headerAboveAttributes.frame
        }

        return nil
    }

    // MARK: - Helper Functions

    /// Get the layout attributes for the first item in the collection. This should be the bottom most item.
    private func firstItemLayoutAttributes() -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        // If we don't have a first item, return nil.
        guard collectionView.numberOfSections > 0, collectionView.numberOfItems(inSection: 0) > 0 else {
            return nil
        }

        return self.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))
    }


    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        var size = self.itemSize
        // If a delegate was assigned, override the items ize with whatever the delegate returns.
        if let delegate = self.delegate {
            size = delegate.bottomToTopColumnLayout(self, itemSizeForItemAtIndexPath: indexPath)
        }
        return size
    }
}
