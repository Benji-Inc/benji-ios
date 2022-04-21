//
//  TimelineLayout.swift
//  TimelineExperiment
//
//  Created by Martin Young on 11/16/21.
//

import UIKit

protocol TimeMachineLayoutItemType {
    /// A date associated with the time machine item
    var date: Date { get }
}

protocol TimeMachineCollectionViewLayoutDataSource: AnyObject {
    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItemType
}

/// A custom layout for a stack of cells laid out along the z axis.
/// The stacks appear similar to Apple's Time Machine interface, with the newest item in front and older items going out into the distance.
/// As the collection view scrolls up and down, the items move away and toward the user respectively.
class TimeMachineCollectionViewLayout: UICollectionViewLayout {

    typealias SectionIndex = Int

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
    var itemHeight: CGFloat = MessageContentView.bubbleHeight + MessageFooterView.height + Theme.ContentOffset.standard.value
    /// Keypoints used to gradually shrink down items as they move away.
    var scalingKeyPoints: [CGFloat] = [1, 0.84, 0.65, 0.4]
    /// The amount of vertical space between the tops of adjacent items.
    var spacingKeyPoints: [CGFloat] = [0, 8, 16, 20]
    /// Top of the back most item on the stack
    var topOfStackY: CGFloat = 0

    /// Key points used for the gradually alpha out items further back in the message stack.
    var alphaKeyPoints: [CGFloat] = [1, 1, 0.75, 0]
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
    /// A cache of all the layout  items mapped to their index paths.
    private(set) var layoutItems: [IndexPath : TimeMachineLayoutItemType] = [:]
    /// Layout items that existed before that latest layout invalidation.
    private var layoutItemsBeforeInvalidation: [IndexPath : TimeMachineLayoutItemType] = [:]

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

    override func invalidateLayout() {
        super.invalidateLayout()

        // Clear the layout attributes caches.
        self.cellLayoutAttributes.removeAll()

        self.layoutItemsBeforeInvalidation = self.layoutItems
        self.layoutItems.removeAll()
    }

    override func prepare() {
        // Calculate and cache the layout attributes for all the items.
        self.forEachIndexPath { indexPath in
            self.layoutItems[indexPath] = self.dataSource?.getTimeMachineItem(forItemAt: indexPath)
            self.cellLayoutAttributes[indexPath] = self.layoutAttributesForItem(at: indexPath)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Return all items whose frames intersect with the given rect.
        let itemAttributes = self.cellLayoutAttributes.values.filter { attributes in
            return rect.intersects(attributes.frame)
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

        let focusPosition = self.focusPosition(for: indexPath)
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

        let centerPoint = self.getItemCenterPoint(withYOffset: yOffset, scale: scale)
        attributes.center = centerPoint
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.alpha = alpha

        return attributes
    }

    // MARK: - Attribute Helpers

    func focusPosition(for indexPath: IndexPath) -> CGFloat {
        return CGFloat(indexPath.item) * self.itemHeight
    }

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

    func getItemCenterPoint(withYOffset yOffset: CGFloat, scale: CGFloat) -> CGPoint {
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
        centerPoint.y += self.topOfStackY
        
        return centerPoint
    }

    // MARK: - Update Animation Handling

    /// Index paths of items that are being inserted.
    private var insertedIndexPaths: Set<IndexPath> = []
    /// Index paths of items that are being deleted.
    private var deletedIndexPaths: Set<IndexPath> = []
    /// The z position before update animations started
    private var zPositionBeforeAnimation: CGFloat = 0
    /// If true, we should adjust the scroll offset so the previously focused item remains in focus.
    private var shouldScrollToPreviouslyFocusedDate = false
    /// The date of the item that was in focus before the animation started.
    private var focusedItemDateBeforeAnimation: Date = .distantFuture

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        self.zPositionBeforeAnimation = self.zPosition
        self.focusedItemDateBeforeAnimation
        = self.getFocusedLayoutItemBeforeAnimation(forZPosition: self.zPosition)?.date ?? .distantFuture

        for update in updateItems {
            switch update.updateAction {
            case .insert:
                guard let indexPath = update.indexPathAfterUpdate,
                      let date = self.dataSource?.getTimeMachineItem(forItemAt: indexPath).date else { break }

                self.insertedIndexPaths.insert(indexPath)
                if date < self.focusedItemDateBeforeAnimation {
                    self.shouldScrollToPreviouslyFocusedDate = true
                }
            case .delete:
                guard let indexPath = update.indexPathBeforeUpdate,
                      let date = self.layoutItemsBeforeInvalidation[indexPath]?.date else {
                    break
                }

                self.deletedIndexPaths.insert(indexPath)

                // Items deleted before the current focused item should increase the offset so the focused
                // item doesn't move.
                if date < self.focusedItemDateBeforeAnimation {
                    self.shouldScrollToPreviouslyFocusedDate = true
                }
            case .reload, .move, .none:
                break
            @unknown default:
                break
            }
        }
    }

    /// Gets the layout item for the item what was in focus before the animation started at the given z position.
    private func getFocusedLayoutItemBeforeAnimation(forZPosition zPosition: CGFloat)
    -> TimeMachineLayoutItemType? {
        if let closestItem = self.layoutItemsBeforeInvalidation.min(by: { kvp1, kvp2 in
            let focus1 = self.focusPosition(for: kvp1.key)
            let focus2 = self.focusPosition(for: kvp2.key)
            return abs(focus1 - zPosition) < abs(focus2 - zPosition)
        }) {
            return closestItem.value
        }

        return nil
    }

    /// NOTE: "Disappearing" does not mean the item is being deleted.
    /// Per the docs: "For each element on screen before the invalidation, finalLayoutAttributesForDisappearingXXX will be called..."
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        // If the item was already visible, there's no need to perform any animation.
        guard self.deletedIndexPaths.contains(itemIndexPath) else { return nil }

        let attributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        attributes?.center.y -= self.zPositionBeforeAnimation - self.zPosition
        return attributes
    }

    /// NOTE: "Appearing" does not mean the item wasn't visible before the animation.
    /// Per the docs: "For each element on screen after the invalidation, initialLayoutAttributesForAppearingXXX will be called..."
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        // Only modify the attributes of items that are actually being inserted.
        guard self.insertedIndexPaths.contains(itemIndexPath) else {
            return super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        }

        // Items being inserted
        let normalizedZOffset: CGFloat
        // Items added to the end of section should start big and shrink down to normal size.
        if itemIndexPath.item == self.numberOfItems(inSection: itemIndexPath.section) - 1 {
            normalizedZOffset = 0
        } else {
            // Items added to the beginning of the section should start small and grow to normal size.
            normalizedZOffset = -1
        }
        let modifiedAttributes = self.layoutAttributesForItemAt(indexPath: itemIndexPath,
                                                                withNormalizedZOffset: normalizedZOffset)
        modifiedAttributes?.center.y += self.zPositionBeforeAnimation - self.zPosition
        modifiedAttributes?.alpha = 0

        return modifiedAttributes
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.insertedIndexPaths.removeAll()
        self.deletedIndexPaths.removeAll()
        self.zPositionBeforeAnimation = 0
        self.shouldScrollToPreviouslyFocusedDate = false
    }

    // MARK: - Scroll Content Offset Handling

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        // Move to the item that was focused before the animation, or an item nearby.
        if self.shouldScrollToPreviouslyFocusedDate,
           let focusPosition = self.getFocusPositionOfItem(with: self.focusedItemDateBeforeAnimation) {

            return CGPoint(x: proposedContentOffset.x, y: focusPosition)
        }

        return proposedContentOffset
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        // When finished scrolling, always settle on a cell in a focused position.
        var newOffset = proposedContentOffset
        newOffset.y = round(newOffset.y, toNearest: self.itemHeight)
        newOffset.y = max(newOffset.y, 0)
        return newOffset
    }

    // MARK: - Scroll/Animation Helper Functions

    /// Gets the focus position of the item associated with the passed in date.
    /// If there is no item with that date, it finds the next oldest item.
    /// If there is still no item found, then nil is returned.
    private func getFocusPositionOfItem(with date: Date) -> CGFloat? {
        var focusedIndexPath: IndexPath?
        let itemCount = self.numberOfItems(inSection: 0)
        for item in (0..<itemCount).reversed() {
            let indexPath = IndexPath(item: item, section: 0)
            guard let itemDate = self.dataSource?.getTimeMachineItem(forItemAt: indexPath).date else {
                continue
            }

            if itemDate <= date {
                focusedIndexPath = indexPath
                break
            }
        }

        if let focusedIndexPath = focusedIndexPath {
            return self.focusPosition(for: focusedIndexPath)
        }

        return nil

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
