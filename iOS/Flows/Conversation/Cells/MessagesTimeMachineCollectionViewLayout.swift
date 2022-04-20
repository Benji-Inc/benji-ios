//
//  MessageTimeMachineCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 12/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit

protocol MessagesTimeMachineCollectionViewLayoutDataSource: TimeMachineCollectionViewLayoutDataSource {
    /// Return true if the item at the given index path was created by the current user.
    func isUserCreatedItem(at indexPath: IndexPath) -> Bool
}

/// A subclass of the TimeMachineLayout used to display messages.
/// In addition to normal time machine functionality, this class also adjusts the color, brightness and other message specific attributes
/// as the items move along the z axis.
class MessagesTimeMachineCollectionViewLayout: TimeMachineCollectionViewLayout {

    override class var layoutAttributesClass: AnyClass {
        return ConversationMessageCellLayoutAttributes.self
    }

    /// Setting this also sets the super class datasource variable.
    weak var messageDataSource: MessagesTimeMachineCollectionViewLayoutDataSource? {
        get { return self.dataSource as? MessagesTimeMachineCollectionViewLayoutDataSource }
        set { self.dataSource = newValue }
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
        attributes.brightness = backgroundBrightness
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
        var frame = CGRect(x: 0,
                           y: 0,
                           width: self.collectionView!.width,
                           height: self.itemHeight)
        frame.center = center
        // Shift the drop zone up a bit to account for the invisible space under the cell.
        frame.top -= 60
        
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

                let isUserCreatedItem: Bool
                if let messageDataSource = self.messageDataSource {
                    isUserCreatedItem = messageDataSource.isUserCreatedItem(at: indexPath)
                } else {
                    isUserCreatedItem = false
                    logDebug("WARNING: No delegate is assigned to MessageLayout.")
                }

                let isInsertedAtFront = indexPath.item == self.numberOfItems(inSection: 0) - 1

                let isScrolledToFront
                = (mostRecentOffset.y - collectionView.contentOffset.y) <= self.itemHeight

                // When a new message comes and we're at the front, always currently scrolled to the
                // new message.
                if (isUserCreatedItem && isInsertedAtFront) || isScrolledToFront {
                    self.shouldScrollToEnd = true
                    break
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
