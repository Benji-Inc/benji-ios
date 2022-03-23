//
//  TimelineLayout.swift
//  TimelineExperiment
//
//  Created by Martin Young on 11/16/21.
//

import UIKit

protocol TimeMachineLayoutItemType {
    /// A unique identifier for the item.
    var layoutId: String { get }
}

protocol TimeMachineCollectionViewLayoutDataSource: AnyObject {
    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItemType
}

class TimeMachineCollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    /// If true, the z ranges for all the items should be recalculated.
    var shouldRecalculateZRanges = true
}

/// A custom layout for a stack of cells laid out along the z axis.
/// The stacks appear similar to Apple's Time Machine interface, with the newest item in front and older items going out into the distance.
/// As the collection view scrolls up and down, the items move away and toward the user respectively.
class TimeMachineCollectionViewLayout: UICollectionViewLayout {

    typealias SectionIndex = Int

    override class var invalidationContextClass: AnyClass {
        return TimeMachineCollectionViewLayoutInvalidationContext.self
    }

    // MARK: - Data Source
    weak var dataSource: TimeMachineCollectionViewLayoutDataSource?

    var sectionCount: Int {
        return self.collectionView?.numberOfSections ?? 0
    }
    func numberOfItems(inSection section: Int) -> Int {
        guard section < self.sectionCount else { return 0 }
        return self.collectionView?.numberOfItems(inSection: section) ?? 0
    }

    // MARK: - Layout Configuration

    /// The height of the cells.
    var itemHeight: CGFloat = 100
    /// Keypoints used to gradually shrink down items as they move away.
    var scalingKeyPoints: [CGFloat] = [1, 0.84, 0.65, 0.4]
    /// The amount of vertical space between the tops of adjacent items.
    var spacingKeyPoints: [CGFloat] = [0, 8, 16, 20]

    /// Key points used for the gradually alpha out items further back in the message stack.
    var alphaKeyPoints: [CGFloat] = [1, 1, 1, 0]
    /// The maximum number of messages to show in each section's stack.
    var stackDepth: Int = 3 {
        didSet { self.invalidateLayout() }
    }

    // MARK: - Layout State

    /// The current position along the Z axis. This is based off of the collectionview's Y content offset.
    /// The z position ranges from 0 to itemCount*itemHeight
    var zPosition: CGFloat {
        return self.collectionView?.contentOffset.y ?? 0
    }
    /// The focus position of the last item in the collection.
    var maxZPosition: CGFloat {
        let itemCount = self.numberOfItems(inSection: 0)
        return CGFloat(clamp(itemCount - 1, min: 0)) * self.itemHeight
    }
    /// A cache of item layout attributes so they don't have to be recalculated.
    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    /// A dictionary of z positions where each item is considered in focus. This means the item is frontmost, most recent, and unscaled.
    private(set) var itemFocusPositions: [IndexPath : CGFloat] = [:]
    /// A cache of the ids for all items.
    private(set) var itemIds: [IndexPath : String] = [:]

    // MARK: - Private State Management

    /// The ids of all items that existed before the latest invalidation.
    private var itemIdsBeforeInvalidation: [IndexPath : String] = [:]

    // MARK: - UICollectionViewLayout Overrides

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView else { return .zero }

            let itemCount = CGFloat(self.numberOfItems(inSection: 0))
            var height = clamp((itemCount - 1), min: 0) * self.itemHeight

            // Adding 1 ensures that we will still receive the pan gesture if the content height is less than
            // the height of the collection view.
            height += collectionView.bounds.height + 1
            return CGSize(width: collectionView.bounds.width, height: height)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func invalidationContext(forBoundsChange newBounds: CGRect)
    -> UICollectionViewLayoutInvalidationContext {

        let invalidationContext = super.invalidationContext(forBoundsChange: newBounds)

        guard let customInvalidationContext
                = invalidationContext as? TimeMachineCollectionViewLayoutInvalidationContext else {
                    return invalidationContext
                }

        // Changing the bounds doesn't affect item z ranges.
        customInvalidationContext.shouldRecalculateZRanges = false

        return customInvalidationContext
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)

        // Clear the layout attributes caches.
        self.cellLayoutAttributes.removeAll()

        guard let customContext = context as? TimeMachineCollectionViewLayoutInvalidationContext else {
            return
        }

        if customContext.shouldRecalculateZRanges {
            self.itemIdsBeforeInvalidation = self.itemIds

            self.itemIds.removeAll()
            self.itemFocusPositions.removeAll()
        }
    }

    override func prepare() {
        // Don't recalculate z ranges if we already have them cached.
        if self.itemFocusPositions.isEmpty {
            self.prepareZPositionsAndRanges()
        }

        // Calculate and cache the layout attributes for all the items.
        self.forEachIndexPath { indexPath in
            self.cellLayoutAttributes[indexPath] = self.layoutAttributesForItem(at: indexPath)
        }
    }

    /// Updates the z ranges dictionary for all items.
    private func prepareZPositionsAndRanges() {
        // Store all the item focus positions for efficiency.
        self.forEachIndexPath { indexPath in
            self.itemFocusPositions[indexPath] = CGFloat(indexPath.item) * self.itemHeight
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Return all items whose frames intersect with the given rect.
        let itemAttributes = self.cellLayoutAttributes.values.filter { attributes in
            return rect.intersects(attributes.frame) && attributes.alpha > 0
        }

        return itemAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If the attributes are cached already, just return those.
        if let attributes = self.cellLayoutAttributes[indexPath]  {
            return attributes
        }

        let normalizedZOffset = self.getNormalizedZOffsetForItem(at: indexPath,
                                                                 givenZPosition: self.zPosition)

        guard (-1...1).contains(normalizedZOffset) else { return nil }
        
        return self.layoutAttributesForItemAt(indexPath: indexPath,
                                              withNormalizedZOffset: normalizedZOffset)
    }

    private func getNormalizedZOffsetForItem(at indexPath: IndexPath,
                                             givenZPosition zPosition: CGFloat) -> CGFloat {

        guard let focusPosition = self.itemFocusPositions[indexPath] else { return 0 }
        let vectorToCurrentZ = zPosition - focusPosition

        let normalizedZOffset: CGFloat

        if 0 < vectorToCurrentZ {
            // The item's z range is behind the current zPosition.
            normalizedZOffset = -vectorToCurrentZ/(self.itemHeight*CGFloat(self.stackDepth))
        } else if vectorToCurrentZ < 0 {
            // The item's z range is in front of the current zPosition.
            normalizedZOffset = -vectorToCurrentZ/self.itemHeight
        } else {
            // The item's range contains the current zPosition
            normalizedZOffset = 0
        }

        return normalizedZOffset
    }

    /// Returns the UICollectionViewLayoutAttributes for the item at the given indexPath configured with the specified normalized Z Offset.
    /// The normalized Z Offset is a value bewteen -1 and 1.
    /// -1 means the item is scaled down and moved away as much as possible before it disappears.
    /// 0 means the item is in focus. It's the frontmost of its stack and not scaled at all.
    /// 1 means the item is scaled up and moved forward as much as possible before it disappears.
    func layoutAttributesForItemAt(indexPath: IndexPath,
                                   withNormalizedZOffset normalizedZOffset: CGFloat) -> UICollectionViewLayoutAttributes? {

        guard let collectionView = self.collectionView else { return nil }

        var scale: CGFloat
        var yOffset: CGFloat
        var alpha: CGFloat

        if normalizedZOffset < 0 {
            // Scaling the item down to simulate it moving away from the user.
            scale = lerp(abs(normalizedZOffset), keyPoints: self.scalingKeyPoints)
            yOffset = lerp(abs(normalizedZOffset), keyPoints: self.spacingKeyPoints)
            alpha = lerp(abs(normalizedZOffset), keyPoints: self.alphaKeyPoints)
        } else if normalizedZOffset > 0 {
            // Scale the item up to simulate it moving closer to the user.
            scale = normalizedZOffset + 1
            yOffset = normalizedZOffset * -self.itemHeight * 1
            alpha = 1 - normalizedZOffset
        } else {
            // If current z position is within the item's z range, don't adjust its scale or position.
            scale = 1
            yOffset = 0
            alpha = 1
        }

        let layoutClass = type(of: self).layoutAttributesClass as? UICollectionViewLayoutAttributes.Type
        guard let attributes = layoutClass?.init(forCellWith: indexPath) else { return nil }

        // Make sure items in the front are drawn over items in the back.
        attributes.zIndex = indexPath.item
        attributes.bounds.size = CGSize(width: collectionView.width, height: self.itemHeight)

        let centerPoint = self.getItemCenterPoint(in: indexPath.section,
                                                  withYOffset: yOffset,
                                                  scale: scale)
        attributes.center = centerPoint
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.alpha = alpha

        return attributes
    }

    // MARK: - Attribute Helpers

    /// Gets the index path of the frontmost item in the collection.
    func getFrontmostIndexPath() -> IndexPath? {
        var indexPathCandidate: IndexPath?

        for i in (0..<self.numberOfItems(inSection: 0)).reversed() {
            let indexPath = IndexPath(item: i, section: 0)

            if indexPathCandidate == nil {
                indexPathCandidate = indexPath
                continue
            }

            let itemZPosition = CGFloat(i) * self.itemHeight

            if itemZPosition - self.zPosition >= 0 {
                indexPathCandidate = indexPath
            }
        }

        return indexPathCandidate
    }

    func getItemCenterPoint(in section: SectionIndex,
                            withYOffset yOffset: CGFloat,
                            scale: CGFloat) -> CGPoint {
        
        guard let collectionView = self.collectionView else { return .zero }
        
        let contentRect = CGRect(x: collectionView.contentOffset.x,
                                 y: collectionView.contentOffset.y,
                                 width: collectionView.bounds.size.width,
                                 height: collectionView.bounds.size.height)

        let maxSpacing = self.spacingKeyPoints.last ?? 0
        var centerPoint = CGPoint(x: contentRect.midX, y: contentRect.top + maxSpacing + self.itemHeight)

        centerPoint.y -= self.itemHeight.half
        centerPoint.y -= self.itemHeight.half - self.itemHeight.half * scale
        centerPoint.y -= yOffset
        
        return centerPoint
    }

    // MARK: - Update Animation Handling

    /// Ids of items that are being inserted.
    private var insertedIds: Set<String> = []
    /// Ids of items that are being deleted.
    private var deletedIds: Set<String> = []
    /// Ids of items that that were visible before the animation started.
    private var idsVisibleBeforeAnimation: Set<String> = []
    /// How much to adjust the proposed scroll offset.
    private var scrollOffsetAdjustment: CGFloat = 0
    /// The z position before update animations started
    private var zPositionBeforeAnimation: CGFloat = 0

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        self.zPositionBeforeAnimation = self.zPosition

        for update in updateItems {
            switch update.updateAction {
            case .insert:
                guard let indexPath = update.indexPathAfterUpdate else { break }
                guard let insertedId
                        = self.dataSource?.getTimeMachineItem(forItemAt: indexPath).layoutId else { break }

                self.insertedIds.insert(insertedId)

                let itemFocusPosition = CGFloat(indexPath.item) * self.itemHeight
                if itemFocusPosition < self.zPosition {
                    self.scrollOffsetAdjustment += self.itemHeight
                }

            case .delete:
                guard let indexPath = update.indexPathBeforeUpdate else { break }
                guard let deletedId
                        = self.dataSource?.getTimeMachineItem(forItemAt: indexPath).layoutId else { break }

                self.deletedIds.insert(deletedId)

                let itemFocusPosition = CGFloat(indexPath.item) * self.itemHeight

                if itemFocusPosition < self.zPosition {
                    self.scrollOffsetAdjustment -= self.itemHeight
                }
            case .reload, .move, .none:
                break
            @unknown default:
                break
            }
        }
    }

    /// NOTE: Disappearing does not mean that the item will not be visible after the animation.
    /// Per the docs:  "For each element on screen before the invalidation, finalLayoutAttributesForDisappearingXXX will be called..."
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        // Remember which items were visible before the animation started so we don't attempt to modify
        // their animations later.
        if let itemId = self.itemIdsBeforeInvalidation[itemIndexPath] {
            self.idsVisibleBeforeAnimation.insert(itemId)

            // Items that are just moving are marked as "disappearing" by the collection view.
            // Don't animate changes to these items or else weird animation issues will arise.
            guard self.deletedIds.contains(itemId) else { return nil }
        }

        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
    }

    /// NOTE: "Appearing" does not mean the item wasn't visible before the animation.
    /// Per the docs: "For each element on screen after the invalidation, initialLayoutAttributesForAppearingXXX will be called..."
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)

        // Don't modify the attributes of items that were visible before the animation started.
        guard let appearingId = self.itemIds[itemIndexPath],
              !self.idsVisibleBeforeAnimation.contains(appearingId) else { return attributes }

        // Items moving into visibility
        // If the item existed before (wasn't just inserted), but was not visible,
        // modify it's attributes to make it appear properly.
        if !self.insertedIds.contains(appearingId) {
            var normalizedZOffset = self.getNormalizedZOffsetForItem(at: itemIndexPath,
                                                                     givenZPosition: self.zPositionBeforeAnimation)
            normalizedZOffset = clamp(normalizedZOffset, -1, 1)
            let modifiedAttributes = self.layoutAttributesForItemAt(indexPath: itemIndexPath,
                                                                    withNormalizedZOffset: normalizedZOffset)

            modifiedAttributes?.center.y += self.zPositionBeforeAnimation - self.zPosition

            return modifiedAttributes
        }

        // Items being inserted
        let normalizedZOffset: CGFloat
        if itemIndexPath.item == self.numberOfItems(inSection: itemIndexPath.section) - 1 {
            if itemIndexPath.section == 0 {
                normalizedZOffset = 1
            } else {
                normalizedZOffset = 0
            }
        } else {
            normalizedZOffset = -1
        }
        let modifiedAttributes = self.layoutAttributesForItemAt(indexPath: itemIndexPath,
                                                                withNormalizedZOffset: normalizedZOffset)

        modifiedAttributes?.center.y += self.zPositionBeforeAnimation - self.zPosition

        return modifiedAttributes
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.insertedIds.removeAll()
        self.deletedIds.removeAll()
        self.idsVisibleBeforeAnimation.removeAll()
        self.zPositionBeforeAnimation = 0
        self.scrollOffsetAdjustment = 0
    }

    // MARK: - Scroll Content Offset Handling

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + self.scrollOffsetAdjustment)
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        // When finished scrolling, always settle on a cell in a focused position.
        var newOffset = proposedContentOffset
        newOffset.y = round(newOffset.y, toNearest: self.itemHeight)
        newOffset.y = max(newOffset.y, 0)
        return newOffset
    }
}

// MARK: - Helper Functions

extension TimeMachineCollectionViewLayout {

    /// Runs the passed in closure on every valid index path in the collection view.
    private func forEachIndexPath(_ apply: (IndexPath) -> Void) {
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
