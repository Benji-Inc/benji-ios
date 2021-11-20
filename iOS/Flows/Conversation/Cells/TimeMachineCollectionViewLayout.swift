//
//  TimelineLayout.swift
//  TimelineExperiment
//
//  Created by Martin Young on 11/16/21.
//

import Foundation
import UIKit
import StreamChat

/// A custom layout for conversation messages. Up to two message cells section are each displayed as a stack along the z axis.
/// The stacks appear similar to Apple's Time Machine interface, with older messages going out into the distance.
/// As the collection view scrolls up and down, the messages move away or toward the user.
class TimelineCollectionViewLayout: UICollectionViewLayout {

    private typealias SectionIndex = Int

    weak var dataSource: ConversationMessageCellDataSource?

    /// The size of the cells.
    var itemSize = CGSize(width: 200, height: 100)

    /// A cache of item layout attributes so they don't have to be recalculated.
    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    /// A dictionary of z ranges for all the items. A z range represents the range that each item will be the frontmost of its section
    /// and its scale will be unaltered.
    private var zRangesDict: [IndexPath : Range<CGFloat>] = [:]
    /// The current position along the Z axis. This is based off of the collectionview's Y content offset.
    private var zPosition: CGFloat {
        return self.collectionView?.contentOffset.y ?? 0
    }

    private var sectionCount: Int {
        return self.collectionView?.numberOfSections ?? 0
    }
    private func numberOfItems(inSection section: Int) -> Int {
        guard section < self.sectionCount else { return 0 }
        return self.collectionView?.numberOfItems(inSection: section) ?? 0
    }

    // MARK: - UICollectionViewLayout Overrides

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView, collectionView.frame != .zero else { return .zero }

            let itemCount = CGFloat(self.numberOfItems(inSection: 0) + self.numberOfItems(inSection: 1))
            var height = (itemCount - 1) * self.itemSize.height
            height += collectionView.bounds.height
            return CGSize(width: collectionView.bounds.width, height: height)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func invalidateLayout() {
        super.invalidateLayout()

        // Clear the layout attributes caches.
        self.cellLayoutAttributes.removeAll()
        self.zRangesDict.removeAll()
    }

    override func prepare() {
        // Get all the items and sort them by value.
        self.prepareZRanges()

        // Calculate and cache the layout attributes for the items in each section.
        self.forEachIndexPath { indexPath in
            self.cellLayoutAttributes[indexPath] = self.layoutAttributesForItem(at: indexPath)
        }
    }

    private func prepareZRanges() {
        guard let dataSource = self.dataSource else { return }

        // Get all of the items and sort them by value. This combines all the sections into a flat list.
        var sortedItems: [(item: ConversationMessageItem, indexPath: IndexPath)] = []
        self.forEachIndexPath { indexPath in
            guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
            sortedItems.append((item, indexPath))
        }
        sortedItems.sort { itemData1, itemData2 in
            let message1 = ChatClient.shared.message(cid: itemData1.item.channelID,
                                                     id: itemData1.item.messageID)
            let message2 = ChatClient.shared.message(cid: itemData2.item.channelID,
                                                     id: itemData2.item.messageID)
            return message1.createdAt < message2.createdAt
        }

        for (sortedItemsIndex, currentItem) in sortedItems.enumerated() {
            let currentSection = currentItem.indexPath.section
            let currentItemIndex = currentItem.indexPath.item

            var startZ: CGFloat = 0
            // Each item's z range starts after the end of the previous item's range within its section.
            if let previousRangeInSection = self.zRangesDict[IndexPath(item: currentItemIndex - 1,
                                                                      section: currentSection)] {

                startZ = previousRangeInSection.upperBound + self.itemSize.height
            }

            var endZ = startZ
            // Each item's z range ends before the beginning of the next item's range from within its section.
            if sortedItemsIndex + 1 < sortedItems.count {
                for nextIndex in (sortedItemsIndex+1)..<sortedItems.count {
                    let nextItem = sortedItems[nextIndex]

                    if currentSection == nextItem.indexPath.section {
                        endZ = CGFloat(nextIndex) * self.itemSize.height - self.itemSize.height
                        break
                    } else if nextIndex == sortedItems.count - 1 {
                        endZ = CGFloat(nextIndex) * self.itemSize.height
                        break
                    }
                }
            }

            self.zRangesDict[currentItem.indexPath] = startZ..<endZ
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Return all items whose frames intersect with the given rect and aren't invisible.
        let itemAttributes = self.cellLayoutAttributes.values.filter { attributes in
            return attributes.alpha > 0 && rect.intersects(attributes.frame)
        }

        return itemAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.cellLayoutAttributes[indexPath]  {
            return attributes
        }

        // All items in a section are positioned relative to its frontmost item.
        guard let frontmostIndexPath = self.getFrontmostIndexPath(in: indexPath.section) else { return nil }

        let offsetFromFrontmost = CGFloat(frontmostIndexPath.item - indexPath.item)*self.itemSize.height
        let frontmostZOffset = self.getFrontmostItemZOffset(in: indexPath.section)
        let zDifference = -(frontmostZOffset+offsetFromFrontmost)

        let attributes = ConversationMessageCellLayoutAttributes(forCellWith: indexPath)
        // Make sure items in the front are drawn over items in the back.
        attributes.zIndex = indexPath.item
        attributes.frame.size = self.itemSize

        var scale: CGFloat = 1
        var yOffset: CGFloat = 0
        var alpha: CGFloat = 1

        if zDifference > 0 {
            scale = min(zDifference/(self.itemSize.height), 1) + 1
            yOffset = (scale-1) * -self.itemSize.height * 2
            alpha = 2 - scale
        } else if zDifference < 0 {
            let normalized = -zDifference/(self.itemSize.height*5)
            scale = 1-normalized
            yOffset = (normalized) * self.itemSize.height
            alpha = 1-easeInExpo(normalized)
        } else {
            scale = 1
            yOffset = 0
            alpha = 1
        }

        let centerPoint = self.getCenterPoint(for: indexPath.section, withNormalizedYOffset: yOffset)
        attributes.center = centerPoint
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.alpha = alpha

        attributes.shouldShowText = true
        attributes.backgroundColor = .white
        attributes.shouldShowTail = true
        attributes.bubbleTailOrientation = indexPath.section == 0 ? .up : .down

        return attributes
    }

    private func getFrontmostIndexPath(in section: SectionIndex) -> IndexPath? {
        var indexPathCandidate: IndexPath?

        for i in (0..<self.numberOfItems(inSection: section)).reversed() {
            let indexPath = IndexPath(item: i, section: section)

            if indexPathCandidate == nil {
                indexPathCandidate = indexPath
                continue
            }

            guard let range = self.zRangesDict[indexPath] else { continue }
            if range.vector(to: self.zPosition) <= 0 {
                indexPathCandidate = indexPath
            }
        }

        return indexPathCandidate
    }

    private func getFrontmostItemZOffset(in section: SectionIndex) -> CGFloat {
        guard let frontmostIndexPath = self.getFrontmostIndexPath(in: section) else { return 0 }

        guard let frontmostRange = self.zRangesDict[frontmostIndexPath] else { return 0 }

        return frontmostRange.vector(to: self.zPosition)
    }

    private func getCenterPoint(for section: SectionIndex,
                                withNormalizedYOffset yOffset: CGFloat) -> CGPoint {

        guard let collectionView = self.collectionView else { return .zero }
        let contentRect = CGRect(x: collectionView.contentOffset.x,
                                 y: collectionView.contentOffset.y,
                                 width: collectionView.bounds.size.width,
                                 height: collectionView.bounds.size.height)
        var centerPoint = CGPoint(x: contentRect.midX, y: contentRect.midY)

        if section == 0 {
            centerPoint.y -= self.itemSize.height * 0.75
            centerPoint.y += yOffset*0.75
        } else {
            centerPoint.y += self.itemSize.height * 0.75
            centerPoint.y -= yOffset*0.75
        }

        return centerPoint
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        // When finished scrolling, always settle on a cell in a centered position.
        var newOffset = proposedContentOffset
        newOffset.y = round(newOffset.y, toNearest: self.itemSize.height)
        newOffset.y = max(newOffset.y, 0)
        return newOffset
    }
}


private func easeInExpo(_ x: CGFloat) -> CGFloat {
    return x == 0 ? 0 : pow(2, 10 * x - 10)
}

private func easeInCubic(_ x: CGFloat) -> CGFloat {
    return x * x * x
}

private func round(_ value: CGFloat, toNearest: CGFloat) -> CGFloat {
    return round(value / toNearest) * toNearest
}

extension TimelineCollectionViewLayout {

    /// Runs the passed in closure on every valid index path in the collection view.
    func forEachIndexPath(_ apply: (IndexPath) -> Void) {
        let sectionCount = self.sectionCount
        for section in 0..<sectionCount {
            let itemCount = self.numberOfItems(inSection: section)
            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                apply(indexPath)
            }
        }
    }
}


extension Range where Bound: Numeric {

    func vector(to value: Bound) -> Bound {
        if value < self.lowerBound {
            return value - self.lowerBound
        } else if value > self.upperBound {
            return value - self.upperBound
        }

        return Bound.zero
    }
}
