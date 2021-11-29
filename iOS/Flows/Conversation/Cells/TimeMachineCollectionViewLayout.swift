//
//  TimelineLayout.swift
//  TimelineExperiment
//
//  Created by Martin Young on 11/16/21.
//

import Foundation
import UIKit
import StreamChat

protocol TimeMachineCollectionViewLayoutDataSource: AnyObject {
    func getConversation(forItemAt indexPath: IndexPath) -> Conversation?
    func getMessage(forItemAt indexPath: IndexPath) -> Messageable?
}

class TimeMachineCollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    /// If true, the z ranges for all the items should be recalculated.
    var shouldRecalculateZRanges = true
}

/// A custom layout for conversation messages. Up to two message cell sections are each displayed as a stack along the z axis.
/// The stacks appear similar to Apple's Time Machine interface, with the newest message in front and older messages going out into the distance.
/// As the collection view scrolls up and down, the messages move away and toward the user respectively.
class TimeMachineCollectionViewLayout: UICollectionViewLayout {

    private typealias SectionIndex = Int

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
    var itemHeight: CGFloat = 88 {
        didSet { self.invalidateLayout() }
    }
    /// The amount of vertical space between the tops of adjacent items.
    var spacingKeyPoints: [CGFloat] = [0, 12, 20, 24]
    /// The maximum number of messages to show in each section's stack.
    var stackDepth: Int = 3 {
        didSet { self.invalidateLayout() }
    }
    /// If true, the message status decoration views should be displayed.
    var showMessageStatus: Bool = false {
        didSet { self.invalidateLayout() }
    }

    // MARK: - Layout State

    /// A cache of item layout attributes so they don't have to be recalculated.
    private var cellLayoutAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    /// A cache of layout attributes for decoration views.
    private var decorationLayoutAttributes: [SectionIndex : UICollectionViewLayoutAttributes] = [:]
    /// A dictionary of z ranges for all the items. A z range represents the range that each item will be frontmost in its section
    /// and its scale will be unaltered.
    private var zRangesDict: [IndexPath : Range<CGFloat>] = [:]
    /// The current position along the Z axis. This is based off of the collectionview's Y content offset.
    private var zPosition: CGFloat {
        return self.collectionView?.contentOffset.y ?? 0
    }

    override init() {
        super.init()
        self.initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initialize()
    }

    private func initialize() {
        self.register(MessageStatusView.self, forDecorationViewOfKind: MessageStatusView.objectIdentifier)
    }

    // MARK: - UICollectionViewLayout Overrides

    override var collectionViewContentSize: CGSize {
        get {
            guard let collectionView = collectionView else { return .zero }

            let itemCount = CGFloat(self.numberOfItems(inSection: 0) + self.numberOfItems(inSection: 1))
            var height = (itemCount - 1) * self.itemHeight

            // Plus 1 ensures that we will still receive the pan gesture, regardless of content size
            height += collectionView.bounds.height + 1
            return CGSize(width: collectionView.bounds.width, height: height)
        }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // The positions of the items need to be recalculated for every change to the bounds.
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

        guard let customContext = context as? TimeMachineCollectionViewLayoutInvalidationContext else { return }

        // Clear the layout attributes caches.
        self.cellLayoutAttributes.removeAll()
        self.decorationLayoutAttributes.removeAll()

        if customContext.shouldRecalculateZRanges {
            self.zRangesDict.removeAll()
        }
    }

    override func prepare() {
        // Don't recalculate z ranges if we already have them cached.
        if self.zRangesDict.isEmpty {
            self.prepareZRanges()
        }

        // Calculate and cache the layout attributes for the items in each section.
        self.forEachIndexPath { indexPath in
            self.cellLayoutAttributes[indexPath] = self.layoutAttributesForItem(at: indexPath)
        }

        for section in 0..<self.sectionCount {
            self.decorationLayoutAttributes[section]
            = self.layoutAttributesForDecorationView(ofKind: MessageStatusView.objectIdentifier,
                                                     at: IndexPath(item: 0, section: section))
        }
    }

    /// Updates the z ranges dictionary for all items.
    private func prepareZRanges() {
        guard let dataSource = self.dataSource else {
            logDebug("Warning: Data source not initialized in \(self)")
            return
        }

        // Get all of the items and sort them by value. This combines all the sections into a flat list.
        var sortedItemIndexPaths: [IndexPath] = []
        self.forEachIndexPath { indexPath in
            sortedItemIndexPaths.append(indexPath)
        }
        sortedItemIndexPaths.sort { indexPath1, indexPath2 in
            let message1 = dataSource.getMessage(forItemAt: indexPath1)!
            let message2 = dataSource.getMessage(forItemAt: indexPath2)!
            return message1.createdAt < message2.createdAt
        }

        for (sortedItemsIndex, indexPath) in sortedItemIndexPaths.enumerated() {
            let currentSection = indexPath.section
            let currentItemIndex = indexPath.item

            var startZ = CGFloat(sortedItemsIndex) * self.itemHeight
            // Each item's z range starts after the end of the previous item's range within its section.
            if let previousRangeInSection = self.zRangesDict[IndexPath(item: currentItemIndex - 1,
                                                                      section: currentSection)] {

                startZ = previousRangeInSection.upperBound + self.itemHeight
            }

            var endZ = startZ
            // Each item's z range ends before the beginning of the next item's range from within its section.
            if sortedItemsIndex+1 < sortedItemIndexPaths.count {
                for nextIndex in (sortedItemsIndex+1)..<sortedItemIndexPaths.count {
                    let nextIndexPath = sortedItemIndexPaths[nextIndex]

                    if currentSection == nextIndexPath.section {
                        endZ = CGFloat(nextIndex) * self.itemHeight - self.itemHeight
                        break
                    } else if nextIndex == sortedItemIndexPaths.count - 1 {
                        endZ = CGFloat(nextIndex) * self.itemHeight
                        break
                    }
                }
            }

            self.zRangesDict[indexPath] = startZ..<endZ
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Return all items whose frames intersect with the given rect and aren't invisible.
        var itemAttributes = self.cellLayoutAttributes.values.filter { attributes in
            return attributes.alpha > 0 && rect.intersects(attributes.frame)
        }

        itemAttributes.append(contentsOf: self.decorationLayoutAttributes.values)

        return itemAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        // If the attributes are cached already, just return those.
        if let attributes = self.cellLayoutAttributes[indexPath]  {
            return attributes
        }

        // All items are positioned relative to its frontmost item in their section.
        guard let frontmostIndexPath = self.getFrontmostIndexPath(in: indexPath.section) else { return nil }

        // OPTIMIZATION: Don't calculate attributes for items that definitely won't be visible.
        guard (-1..<self.stackDepth+1).contains(frontmostIndexPath.item - indexPath.item) else {
            return nil
        }

        let indexOffsetFromFrontmost = CGFloat(frontmostIndexPath.item - indexPath.item)
        let offsetFromFrontmost = indexOffsetFromFrontmost*self.itemHeight

        let frontmostVectorToCurrentZ = self.getFrontmostItemZOffset(in: indexPath.section)
        let vectorToCurrentZ = frontmostVectorToCurrentZ+offsetFromFrontmost

        var scale: CGFloat = 1
        var yOffset: CGFloat = 0
        var alpha: CGFloat = 1

        if vectorToCurrentZ > 0 {
            // The item's z range is behind the current zPosition.
            // Start scaling it down to simulate it moving away from the user.
            let normalized = vectorToCurrentZ/(self.itemHeight*CGFloat(self.stackDepth))
            scale = clamp(1-normalized, min: 0)
            yOffset = lerp(normalized, keyPoints: self.spacingKeyPoints)
            alpha = scale == 0 ? 0 : 1
        } else if vectorToCurrentZ < 0 {
            // The item's z range is in front of the current zPosition.
            // Scale it up to simulate it moving closer to the user.
            let normalized = (-vectorToCurrentZ)/self.itemHeight
            scale = clamp(normalized, max: 1) + 1
            yOffset = normalized * -self.itemHeight * 2
            alpha = 1 - normalized
        } else {
            // If current z position is within the item's z range, don't adjust its scale or position.
            scale = 1
            yOffset = 0
            alpha = 1
        }

        let attributes = ConversationMessageCellLayoutAttributes(forCellWith: indexPath)
        // Make sure items in the front are drawn over items in the back.
        attributes.zIndex = indexPath.item
        attributes.bounds.size = CGSize(width: collectionView.width, height: self.itemHeight)

        let centerPoint = self.getCenterPoint(for: indexPath.section,
                                                 withYOffset: yOffset,
                                                 scale: scale)
        attributes.center = centerPoint
        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.alpha = alpha

        // Objects closer to the front of the stack should be brighter.
        let backgroundBrightness: CGFloat = clamp(1 - indexOffsetFromFrontmost * 0.1, max: 1)
        var backgroundColor: Color = .lightGray

        if indexPath == self.getMostRecentVisibleIndexPath() {
            backgroundColor = .white
        }

        attributes.brightness = backgroundBrightness
        attributes.backgroundColor = backgroundColor
        attributes.shouldShowTail = true
        attributes.bubbleTailOrientation = indexPath.section == 0 ? .up : .down

        return attributes
    }

    override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                    at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

        // If the attributes are cached already, just return those.
        if let attributes = self.decorationLayoutAttributes[indexPath.section] {
            return attributes
        }

        guard let frontmostItemIndexPath = self.getFrontmostIndexPath(in: indexPath.section),
              let frontmostAttributes = self.layoutAttributesForItem(at: frontmostItemIndexPath) else {
                  return nil
              }

        guard let conversation = self.dataSource?.getConversation(forItemAt: frontmostItemIndexPath),
              let messageable = self.dataSource?.getMessage(forItemAt: frontmostItemIndexPath) else {
                  return nil
              }

        let message = ChatClient.shared.message(cid: conversation.cid, id: messageable.id)

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

        if let read = conversation.reads.first(where: { read in
            return read.user.id == message.authorID
        }) {
            attributes.status = ChatMessageStatus(read: read, message: message)
        }

        attributes.alpha = self.showMessageStatus ? 1 : 0

        return attributes
    }

    // MARK: - Attribute Helpers

    /// Gets the index path of the frontmost item in the given section.
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

    /// Gets the z vector from current frontmost item's z range to the current z position.
    private func getFrontmostItemZOffset(in section: SectionIndex) -> CGFloat {
        guard let frontmostIndexPath = self.getFrontmostIndexPath(in: section) else { return 0 }

        guard let frontmostRange = self.zRangesDict[frontmostIndexPath] else { return 0 }

        return frontmostRange.vector(to: self.zPosition)
    }


    private func getMostRecentVisibleIndexPath() -> IndexPath? {
        let sectionCount = self.sectionCount

        var frontmostIndexes: [IndexPath] = []
        for i in 0..<sectionCount {
            guard let frontmostIndex = self.getFrontmostIndexPath(in: i) else { continue }
            guard let range = self.zRangesDict[frontmostIndex] else { continue }

            if range.vector(to: self.zPosition) > -self.itemHeight {
                frontmostIndexes.append(frontmostIndex)
            }
        }

        return frontmostIndexes.max { indexPath1, indexPath2 in
            guard let lowerBound1 = self.zRangesDict[indexPath1]?.lowerBound else { return true }
            guard let lowerBound2 = self.zRangesDict[indexPath2]?.lowerBound else { return false }
            return lowerBound1 < lowerBound2
        }
    }

    func getMostRecentItemContentOffset() -> CGPoint? {
        guard let mostRecentIndex = self.zRangesDict.max(by: { kvp1, kvp2 in
            return kvp1.value.lowerBound < kvp2.value.lowerBound
        })?.key else { return nil }

        guard let upperBound = self.zRangesDict[mostRecentIndex]?.upperBound else { return nil }
        return CGPoint(x: 0, y: upperBound)
    }

    private func getCenterPoint(for section: SectionIndex,
                                withYOffset yOffset: CGFloat,
                                scale: CGFloat) -> CGPoint {

        guard let collectionView = self.collectionView else { return .zero }
        let contentRect = CGRect(x: collectionView.contentOffset.x,
                                 y: collectionView.contentOffset.y,
                                 width: collectionView.bounds.size.width,
                                 height: collectionView.bounds.size.height)
        var centerPoint = CGPoint(x: contentRect.midX, y: contentRect.top + Theme.contentOffset)

        if section == 0 {
            centerPoint.y += self.itemHeight.half
            centerPoint.y += yOffset
            centerPoint.y += self.itemHeight.half * (1-scale)
        } else {
            centerPoint.y += self.itemHeight.doubled
            centerPoint.y -= yOffset
            centerPoint.y -= self.itemHeight.half * (1-scale)
        }

        return centerPoint
    }

    func getDropZoneColor() -> Color? {
        guard let ip = self.getMostRecentVisibleIndexPath(),
                let attributes = self.layoutAttributesForItem(at: ip) as? ConversationMessageCellLayoutAttributes else { return nil }
        if ip.section == 1 {
            return attributes.backgroundColor
        } else {
            return .lightGray
        }
    }

    func getDropZoneFrame() -> CGRect {
        let center = self.getCenterPoint(for: 1, withYOffset: 0, scale: 1)
        var frame = CGRect(x: Theme.contentOffset.half,
                           y: 0,
                           width: self.collectionView!.width - Theme.contentOffset,
                           height: self.itemHeight - MessageContentView.bubbleTailLength - Theme.contentOffset)
        frame.centerY = center.y - MessageContentView.bubbleTailLength.half
        return frame
    }

    // MARK: - Content Offset Handling

    private var shouldScrollToEnd = false

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        guard let collectionView = self.collectionView,
        let mostRecentOffset = self.getMostRecentItemContentOffset() else { return }

        for update in updateItems {
            if let indexPath = update.indexPathAfterUpdate, update.updateAction == .insert {
                // Always scroll to the end for new user messages, or if we're currently scrolled to the
                // most recent message.
                if indexPath.section == 1
                    || (mostRecentOffset.y - collectionView.contentOffset.y) <= self.itemHeight {
                    self.shouldScrollToEnd = true
                }
            }
        }
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.shouldScrollToEnd = false
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard self.shouldScrollToEnd, let offset = self.getMostRecentItemContentOffset() else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

        return offset
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        // When finished scrolling, always settle on a cell in a centered position.
        var newOffset = proposedContentOffset
        newOffset.y = round(newOffset.y, toNearest: self.itemHeight)
        newOffset.y = max(newOffset.y, 0)
        return newOffset
    }
}

extension TimeMachineCollectionViewLayout {

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
