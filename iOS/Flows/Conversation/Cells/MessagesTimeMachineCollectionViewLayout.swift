//
//  MessageTimeMachineCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 12/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit

/// A subclass of the TimeMachineLayout used to display messages.
/// In addition to normal time machine functionality, this class also adjusts the color, brightness and other message specific attributes
/// as the items move along the z axis.
class MessagesTimeMachineCollectionViewLayout: TimeMachineCollectionViewLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }
    
    // MARK: - Layout Configuration

    /// How bright the background of the frontmost item is. 0 is black, 1 is full brightness.
    var frontmostBrightness: CGFloat = 1
    /// How bright the background of the backmost item is. This is based off of the frontmost item brightness.
    var backmostBrightness: CGFloat {
        return self.frontmostBrightness - CGFloat(self.stackDepth+1)*0.2
    }

    var uiState: ConversationUIState = .read
    
    override func layoutAttributesForItemAt(indexPath: IndexPath,
                                            withNormalizedZOffset normalizedZOffset: CGFloat) -> UICollectionViewLayoutAttributes? {

        let attributes = super.layoutAttributesForItemAt(indexPath: indexPath,
                                                         withNormalizedZOffset: normalizedZOffset)

        guard let attributes = attributes as? ConversationMessageCellLayoutAttributes else {
            return attributes
        }

        var backgroundBrightness: CGFloat
        if normalizedZOffset < 0 {
            // Darken the item as it moves away
            backgroundBrightness = lerp(abs(normalizedZOffset),
                                        start: self.frontmostBrightness,
                                        end: self.backmostBrightness)
        } else {
            // Items should be at full brightness when at the front of the stack.
            backgroundBrightness = self.frontmostBrightness
        }

        let detailAlpha = 1 - abs(normalizedZOffset) / 0.2

        attributes.backgroundColor = ThemeColor.D1.color
        attributes.textColor = ThemeColor.T3.color

        attributes.brightness = backgroundBrightness
        attributes.shouldShowTail = false
        attributes.bubbleTailOrientation = .down
        attributes.detailAlpha = detailAlpha

        return attributes
    }

    // MARK: - Attribute Helpers

    func getFrontmostCell() -> MessageCell? {
        guard let ip = self.getFrontmostIndexPath(),
              let cell = self.collectionView?.cellForItem(at: ip) as? MessageCell else {
                  return nil
              }
        return cell
    }

    func getDropZoneFrame() -> CGRect {
        let center = self.getItemCenterPoint(withYOffset: 0, scale: 1)
        let padding = Theme.ContentOffset.long.value.doubled
        var frame = CGRect(x: padding.half,
                           y: 0,
                           width: self.collectionView!.width - padding,
                           height: 40)
        switch uiState {
        case .read:
            frame.centerY = center.y + (self.collectionView!.height * 0.25)
        case .write:
            frame.centerY = center.y + (self.collectionView!.height * 0.15)
        }
        
        return frame
    }

    private func getMostRecentItemContentOffset() -> CGPoint? {
        return CGPoint(x: 0, y: self.maxZPosition)
    }

    // MARK: - Content Offset and Update Animation Handling

    /// If true, scroll to the most recent item after performing collection view updates.
    private var shouldScrollToEnd = false

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        guard let collectionView = self.collectionView,
              let mostRecentOffset = self.getMostRecentItemContentOffset() else { return }

        for update in updateItems {
            switch update.updateAction {
            case .insert:
                guard let indexPath = update.indexPathAfterUpdate else { break }

                let isScrolledToMostRecent
                = (mostRecentOffset.y - collectionView.contentOffset.y) <= self.itemHeight

                let isMostRecentInBottomSection = indexPath.item == self.numberOfItems(inSection: 1) - 1

                // Always scroll to the end for new user messages, or if we're currently scrolled to the
                // most recent message.
                if isMostRecentInBottomSection || isScrolledToMostRecent {
                    self.shouldScrollToEnd = true
                }
            case .delete, .reload, .move, .none:
                break
            @unknown default:
                break
            }
        }
    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()

        self.shouldScrollToEnd = false
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if self.shouldScrollToEnd, let mostRecentOffset = self.getMostRecentItemContentOffset() {
            return mostRecentOffset
        }

        return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
}
