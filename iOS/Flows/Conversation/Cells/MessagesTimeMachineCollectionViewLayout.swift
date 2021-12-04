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

/// A custom layout for conversation messages. Up to two message cell sections are each displayed as a stack along the z axis.
/// The stacks appear similar to Apple's Time Machine interface, with the newest message in front and older messages going out into the distance.
/// As the collection view scrolls up and down, the messages move away and toward the user respectively.
class MessagesTimeMachineCollectionViewLayout: TimeMachineCollectionViewLayout {

    // MARK: - Layout Configuration

    /// How bright the background of the frontmost item is. 0 is black, 1 is full brightness.
    var frontmostBrightness: CGFloat = 0.89
    /// How bright the background of the backmost item is. This is based off of the frontmost item brightness.
    var backmostBrightness: CGFloat {
        return self.frontmostBrightness - CGFloat(self.stackDepth+1)*0.1
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

        let detailAlpha =  1 - abs(normalizedZOffset)/(self.itemHeight * 0.2)

        // The most recent visible item should be white.
        if let itemFocusPosition = self.itemFocusPositions[indexPath] {
            let normalizedFocusDistance = abs(itemFocusPosition - self.zPosition)/self.itemHeight.half

            backgroundBrightness += lerpClamped(normalizedFocusDistance,
                                                start: 1-self.frontmostBrightness,
                                                end: 0)
        }

        // If there is no message to display for this index path, don't show the cell.
        if self.delegate?.getMessage(forItemAt: indexPath) == nil {
            attributes.alpha = 0
        }

        attributes.backgroundColor = .white
        attributes.brightness = backgroundBrightness
        attributes.shouldShowTail = indexPath.section == 0
        attributes.bubbleTailOrientation = indexPath.section == 0 ? .up : .down
        attributes.detailAlpha = detailAlpha

        return attributes
    }

    // MARK: - Attribute Helpers

    func getDropZoneColor() -> Color? {
        guard let ip = self.getFocusedItemIndexPath(),
                let attributes = self.layoutAttributesForItem(at: ip) as? ConversationMessageCellLayoutAttributes else {
                    return nil
                }

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
                           width: self.collectionView!.width - (Theme.ContentOffset.short.value * 2),
                           height: self.itemHeight - MessageContentView.bubbleTailLength - (Theme.ContentOffset.short.value * 2))
        frame.centerY = center.y - MessageContentView.bubbleTailLength.half
        return frame
    }

    // MARK: - Content Offset Handling/Custom Animations

    /// If true, scroll to the most recent item after performing collection view updates.
    private var shouldScrollToEnd = false
    private var deletedIndexPaths: Set<IndexPath> = []
    private var insertedIndexPaths: Set<IndexPath> = []

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        guard let collectionView = self.collectionView,
        let mostRecentOffset = self.getMostRecentItemContentOffset() else { return }

        for update in updateItems {
            switch update.updateAction {
            case .insert:
                guard let indexPath = update.indexPathAfterUpdate else { break }
                self.insertedIndexPaths.insert(indexPath)

                let isScrolledToMostRecent = (mostRecentOffset.y - collectionView.contentOffset.y) <= self.itemHeight
                // Always scroll to the end for new user messages, or if we're currently scrolled to the
                // most recent message.
                if indexPath.section == 1 || isScrolledToMostRecent {
                    self.shouldScrollToEnd = true
                }
            case .delete:
                guard let indexPath = update.indexPathBeforeUpdate else { break }
                self.deletedIndexPaths.insert(indexPath)
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
        self.insertedIndexPaths.removeAll()
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

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {
        guard deletedIndexPaths.contains(itemIndexPath) else { return nil }

        return super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
    }

    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath)
    -> UICollectionViewLayoutAttributes? {

        let attributes = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)

        // A new message dropped in the user's message stack should appear immediately.
        guard itemIndexPath.section == 1 else {
            return attributes
        }

        // Ensure this is actually a new message and not just a placeholder message.
        if self.insertedIndexPaths.contains(itemIndexPath)
            && self.delegate?.getMessage(forItemAt: itemIndexPath) != nil {
            attributes?.alpha = 1
        }

        return attributes
    }
}
