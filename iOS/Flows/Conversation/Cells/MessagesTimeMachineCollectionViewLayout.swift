//
//  MessageTimeMachineCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 12/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import StreamChat

/// A subclass of the TimeMachineLayout used to display messages.
/// In addition to normal time machine functionality, this class also adjusts the color, brightness and other message specific attributes
/// as the items move along the z axis.
class MessagesTimeMachineCollectionViewLayout: TimeMachineCollectionViewLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }

    // MARK: - Layout Configuration

    var layoutForDropZone: Bool = false
    /// How bright the background of the frontmost item is. 0 is black, 1 is full brightness.
    var frontmostBrightness: CGFloat = 0.89
    /// How bright the background of the backmost item is. This is based off of the frontmost item brightness.
    var backmostBrightness: CGFloat {
        return self.frontmostBrightness - CGFloat(self.stackDepth+1)*0.05
    }

    /// The sort value of the focused right before the most recent invalidation.
    /// This can be used to keep the focused item in place when items are inserted before it.
    private var sortValueOfFocusedItemBeforeInvalidation: Double?
    private var sortValuesBeforeInvalidation: [IndexPath : Double] = [:]

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        // Find the the current focused item
        if let focusedIndexPath = self.itemFocusPositions.min(by: { kvp1, kvp2 in
            return abs(kvp1.value - self.zPosition) < abs(kvp2.value - self.zPosition)
        })?.key {
            self.sortValueOfFocusedItemBeforeInvalidation = self.itemSortValues[focusedIndexPath]
        } else {
            self.sortValueOfFocusedItemBeforeInvalidation = nil
        }

        self.sortValuesBeforeInvalidation = self.itemSortValues

        super.invalidateLayout(with: context)
    }

    override func layoutAttributesForItemAt(indexPath: IndexPath,
                                            withNormalizedZOffset normalizedZOffset: CGFloat) -> UICollectionViewLayoutAttributes? {

        let attributes = super.layoutAttributesForItemAt(indexPath: indexPath,
                                                         withNormalizedZOffset: normalizedZOffset)

        guard let attributes = attributes as? ConversationMessageCellLayoutAttributes else {
            return attributes
        }


        var backgroundBrightness: CGFloat
        if normalizedZOffset < 0 {
            // Dark the item as it moves away
            backgroundBrightness = lerp(abs(normalizedZOffset),
                                        start: self.frontmostBrightness,
                                        end: self.backmostBrightness)
        } else {
            // Items should be at full when at the front of the stack.
            backgroundBrightness = self.frontmostBrightness
        }

        let detailAlpha = 1 - abs(normalizedZOffset) / 0.2
        let textViewAlpha = 1 - abs(normalizedZOffset) / 0.8

        // The most recent visible item should be white.
        if let itemFocusPosition = self.itemFocusPositions[indexPath] {
            let normalizedFocusDistance = abs(itemFocusPosition - self.zPosition)/self.itemHeight.half

            backgroundBrightness += lerpClamped(normalizedFocusDistance,
                                                start: 1-self.frontmostBrightness,
                                                end: 0)
        }

        attributes.backgroundColor = .white
        attributes.brightness = backgroundBrightness
        attributes.shouldShowTail = indexPath.section == 0
        attributes.bubbleTailOrientation = indexPath.section == 0 ? .up : .down
        attributes.detailAlpha = detailAlpha
        attributes.messageContentAlpha = self.layoutForDropZone && indexPath.section == 1 ? 0.0 : textViewAlpha

        return attributes
    }

    // MARK: - Attribute Helpers

    func getDropZoneColor() -> Color? {
        guard let ip = self.getFrontmostIndexPath(in: 1),
                let attributes = self.layoutAttributesForItem(at: ip) as? ConversationMessageCellLayoutAttributes else {
                    return nil
                }

        return attributes.backgroundColor == .white ? .darkGray : .white
    }

    func getBottomFrontMostCell() -> MessageSubcell? {
        guard let ip = self.getFrontmostIndexPath(in: 1), let cell = self.collectionView?.cellForItem(at: ip) as? MessageSubcell else { return nil
        }
        return cell
    }

    func getDropZoneFrame() -> CGRect {
        let center = self.getCenterPoint(for: 1, withYOffset: 0, scale: 1)
        let padding = Theme.ContentOffset.short.value.doubled
        var frame = CGRect(x: padding.half,
                           y: 0,
                           width: self.collectionView!.width - padding,
                           height: MessageContentView.bubbleHeight - padding)
        frame.centerY = center.y - padding - Theme.ContentOffset.short.value
        return frame
    }

    // MARK: - Content Offset Handling/Custom Animations

    /// If true, scroll to the most recent item after performing collection view updates.
    private var shouldScrollToEnd = false
    private var deletedIndexPaths: Set<IndexPath> = []
    /// How much to adjust the proposed scroll offset.
    private var scrollOffset: CGFloat = 0

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        guard let collectionView = self.collectionView,
              let mostRecentOffset = self.getMostRecentItemContentOffset() else { return }

        for update in updateItems {
            switch update.updateAction {
            case .insert:
                guard let indexPath = update.indexPathAfterUpdate else { break }

                if let insertSortValue = self.itemSortValues[indexPath],
                   let previousFocusedSortValue = self.sortValueOfFocusedItemBeforeInvalidation,
                   insertSortValue < previousFocusedSortValue {
                    self.scrollOffset += self.itemHeight
                }

                let isScrolledToMostRecent
                = (mostRecentOffset.y - collectionView.contentOffset.y) <= self.itemHeight

                let isMostRecentInBottomSection = indexPath.item == self.numberOfItems(inSection: 1) - 1

                // Always scroll to the end for new user messages, or if we're currently scrolled to the
                // most recent message.
                if isMostRecentInBottomSection || isScrolledToMostRecent {
                    self.shouldScrollToEnd = true
                }
            case .delete:
                guard let indexPath = update.indexPathBeforeUpdate else { break }
                self.deletedIndexPaths.insert(indexPath)

                if let deleteSortValue = self.sortValuesBeforeInvalidation[indexPath],
                   let previousFocusedSortValue = self.sortValueOfFocusedItemBeforeInvalidation,
                    deleteSortValue <= previousFocusedSortValue {
                    self.scrollOffset -= self.itemHeight
                }
            case .reload, .move, .none:
                break
            @unknown default:
                break
            }
        }
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.shouldScrollToEnd = false
        self.deletedIndexPaths.removeAll()
        self.scrollOffset = 0
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if self.shouldScrollToEnd, let mostRecentOffset = self.getMostRecentItemContentOffset() {
            return mostRecentOffset
        }

        return CGPoint(x: proposedContentOffset.x, y: proposedContentOffset.y + self.scrollOffset)
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {
        // Items that are just moving are marked as "deleted" by the collection view.
        // Only animate changes to items that are actually being deleted otherwise weird animation issues
        // will arise.
        guard self.deletedIndexPaths.contains(itemIndexPath) else { return nil }

        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
    }
}
