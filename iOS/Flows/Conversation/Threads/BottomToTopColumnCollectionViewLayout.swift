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
    func bottomToTopColumnLayout(_ layout: BottomToTopColumnCollectionViewLayout,
                                 headerSizeForSection section: Int) -> CGSize
    func bottomToTopColumnLayout(_ layout: BottomToTopColumnCollectionViewLayout,
                                 footerSizeForSection section: Int) -> CGSize
}

/// A collection view layout that lays out its content in a single column with the first item at the bottom and the last at the top.
class BottomToTopColumnCollectionViewLayout: UICollectionViewLayout {

    /// The default size of the cells. This is ignored if a delegate is assigned.
    var defaultItemSize = CGSize(width: 20, height: 20)
    /// The default vertical spacing between items.
    var defaultItemSpacing: CGFloat = 0
    /// The default size of the header. This is ignored if a delegate is assigned.
    var defaultHeaderSize = CGSize(width: 20, height: 20)
    /// The default size of the footer. This is ignored if a delegate is assigned.
    var defaultFooterSize = CGSize(width: 20, height: 20)

    weak var delegate: BottomToTopColumnCollectionViewLayoutDelegate?

    /// A cache of item layout attributes so they don't have to be recalculated.
    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    private var headerLayoutAttributes: [Int : UICollectionViewLayoutAttributes] = [:]
    private var footerLayoutAttributes: [Int : UICollectionViewLayoutAttributes] = [:]

    private var sectionCount: Int {
        return self.collectionView?.numberOfSections ?? 0
    }
    private func numberOfItems(inSection section: Int) -> Int {
        return self.collectionView?.numberOfItems(inSection: section) ?? 0
    }

    // MARK: - UICollectionViewLayout Overrides

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

        // Invalidate the bounds if the height of the collection view changes.
        return newBounds.size != collectionView.size
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        // Clear the layout attributes cache.
        self.cellLayoutAttributes = [:]
        self.headerLayoutAttributes = [:]
        self.footerLayoutAttributes = [:]
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }

        let sectionCount = collectionView.numberOfSections
        // To better take advantage of caching and improve performance, calculate item frames in reverse.
        // Items with lower indexes are positioned at the bottom of the collection so they rely on
        // the frames of items with higher indexes.
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

            // Calculate and cache the footer layout attributes
            self.footerLayoutAttributes[section]
            = self.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                        at: IndexPath(item: 0, section: section))
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
        let footerAttibutes = self.footerLayoutAttributes.values.filter { attributes in
            return rect.intersects(attributes.frame)
        }

        return itemAttributes + headerAttributes + footerAttibutes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.cellLayoutAttributes[indexPath]  {
            return attributes
        }

        let sectionCount = self.sectionCount

        var yValue: CGFloat = 0

    sectionLoop: for section in (indexPath.section..<sectionCount).reversed() {
        let headerSize = self.sizeForHeader(inSection: section)

        if headerSize.height > 0 {
            yValue += headerSize.height + self.defaultItemSpacing
        }

        let itemCount = self.numberOfItems(inSection: section)
        var startItem = 0
        if indexPath.section == section {
            startItem = indexPath.item
        }
        // No need to calculate the frames of items below this item.
        for item in (startItem..<itemCount).reversed() {
            let currentIndexPath = IndexPath(item: item, section: section)

            if currentIndexPath == indexPath {
                break sectionLoop
            }

            let itemSize = self.sizeForItem(at: currentIndexPath)

            yValue += itemSize.height
            if itemSize.height > 0 && item != 0{
                yValue += self.defaultItemSpacing
            }
        }

        let footerSize = self.sizeForFooter(inSection: section)
        if footerSize.height > 0 {
            yValue += headerSize.height
        }

        yValue += 10
    }

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame.origin = CGPoint(x: 0, y: yValue)
        attributes.frame.size = self.sizeForItem(at: indexPath)

        let itemCount = self.numberOfItems(inSection: indexPath.section)
        attributes.zIndex = itemCount - indexPath.item

        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            return self.layoutAttributesForHeader(inSection: indexPath.section)
        case UICollectionView.elementKindSectionFooter:
            return self.layoutAttributesForFooter(inSection: indexPath.section)
        default:
            return nil
        }
    }

    private func layoutAttributesForHeader(inSection section: Int) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.headerLayoutAttributes[section]  {
            return attributes
        }

        // If the header is zero sized we shouldn't attempt to make a header.
        let headerSize = self.sizeForHeader(inSection: section)
        if headerSize == .zero {
            return nil
        }

        let sectionCount = self.sectionCount

        var yValue: CGFloat = 0
        // Headers are the top of their sections so there's no need to calculate its own section.
        for currentSection in (section + 1..<sectionCount).reversed() {
            let headerSize = self.sizeForHeader(inSection: currentSection)
            if headerSize.height > 0 {
                yValue += headerSize.height + self.defaultItemSpacing
            }

            let itemCount = self.numberOfItems(inSection: currentSection)
            for item in (0..<itemCount).reversed() {
                let indexPath = IndexPath(item: item, section: currentSection)
                let itemSize = self.sizeForItem(at: indexPath)

                if itemSize.height > 0 {
                    yValue += itemSize.height + self.defaultItemSpacing
                }
            }

            let footerSize = self.sizeForFooter(inSection: currentSection)
            if footerSize.height > 0 {
                yValue += headerSize.height + self.defaultItemSpacing
            }
        }

        let attributes
        = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                           with: IndexPath(item: 0, section: section))
        attributes.frame.origin = CGPoint(x: 0, y: yValue)
        attributes.frame.size = headerSize

        return attributes
    }

    private func layoutAttributesForFooter(inSection section: Int) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.footerLayoutAttributes[section]  {
            return attributes
        }

        let footerSize = self.sizeForFooter(inSection: section)
        // If the footer is zero sized we shouldn't attempt to make a footer.
        if footerSize == .zero {
            return nil
        }

        let sectionCount = self.sectionCount

        var yValue: CGFloat = 0

        for currentSection in (section..<sectionCount).reversed() {
            let headerSize = self.sizeForHeader(inSection: currentSection)
            if headerSize.height > 0 {
                yValue += headerSize.height + self.defaultItemSpacing
            }

            let itemCount = self.numberOfItems(inSection: currentSection)
            for item in (0..<itemCount).reversed() {
                let indexPath = IndexPath(item: item, section: currentSection)
                let itemSize = self.sizeForItem(at: indexPath)

                if itemSize.height > 0 {
                    yValue += itemSize.height + self.defaultItemSpacing
                }
            }

            if currentSection == section {
                let footerSize = self.sizeForFooter(inSection: currentSection)
                if footerSize.height > 0 {
                    yValue += headerSize.height + self.defaultItemSpacing
                }
            }
        }

        let attributes
        = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                           with: IndexPath(item: 0, section: section))

        attributes.frame.origin = CGPoint(x: 0, y: yValue)
        attributes.frame.size = footerSize

        return attributes
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

    /// Asks the delegate for the size of the item at the index path. If no delegate is assigned the default item size is used.
    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        // If a delegate was assigned, override the items size with whatever the delegate returns.
        return self.delegate?.bottomToTopColumnLayout(self,
                                                      itemSizeForItemAtIndexPath: indexPath) ?? self.defaultItemSize
    }

    /// Asks the delegate for the size of header in the given section. If no delegate is assigned the default header size is used.
    private func sizeForHeader(inSection section: Int) -> CGSize {
        // If a delegate was assigned, override the header size with whatever the delegate returns.
        return self.delegate?.bottomToTopColumnLayout(self,
                                                      headerSizeForSection: section) ?? self.defaultHeaderSize
    }

    /// Asks the delegate for the size of the item at the index path. If no delegate is assigned the default item size is used.
    private func sizeForFooter(inSection section: Int) -> CGSize {
        // If a delegate was assigned, override the footer size with whatever the delegate returns.
        return self.delegate?.bottomToTopColumnLayout(self,
                                                      footerSizeForSection: section) ?? self.defaultFooterSize
    }
}
