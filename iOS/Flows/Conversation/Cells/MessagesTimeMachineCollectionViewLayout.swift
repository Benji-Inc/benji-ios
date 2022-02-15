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
    
    var messageContentState: MessageContentView.State = .collapsed
    var decorationAttributes: DecorationViewLayoutAttributes?
    var uiState: ConversationUIState = .read
    var hideCenterDecorationView: Bool = false
    
    override func initializeLayout() {
        super.initializeLayout()
        
        self.register(CenterDectorationView.self, forDecorationViewOfKind: CenterDectorationView.kind)
    }
        
    override func prepare() {
        super.prepare()
        
        self.decorationAttributes = DecorationViewLayoutAttributes.init(forDecorationViewOfKind: CenterDectorationView.kind, with: IndexPath(item: 0, section: 0))
        self.decorationAttributes?.bounds.size = CGSize(width: self.collectionView?.width ?? .zero,
                                                        height: 14)
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                    at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case CenterDectorationView.kind:
            if self.sectionCount > 0 {
                self.decorationAttributes?.center = self.getCenterOfItems()
                self.decorationAttributes?.state = self.uiState
                self.decorationAttributes?.isHidden = self.hideCenterDecorationView
                return self.decorationAttributes
            } else {
                return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
            }
        default:
            return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var all = super.layoutAttributesForElements(in: rect)
        if let decorationAttributes = self.layoutAttributesForDecorationView(ofKind: CenterDectorationView.kind, at: IndexPath(item: 0, section: 0)) {
            all?.append(decorationAttributes)
        }
        
        return all
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
            // Darken the item as it moves away
            backgroundBrightness = lerp(abs(normalizedZOffset),
                                        start: self.frontmostBrightness,
                                        end: self.backmostBrightness)
        } else {
            // Items should be at full brightness when at the front of the stack.
            backgroundBrightness = self.frontmostBrightness
        }

        let detailAlpha = 1 - abs(normalizedZOffset) / 0.2
        // The section with the most recent item should be saturated in color

        let focusAmount = self.getFocusAmount(forSection: indexPath.section)
        attributes.sectionFocusAmount = focusAmount

        // Figure out how saturated the color should be.
        // Lerp between D1 to L1
        let unsaturatedColor = ThemeColor.L1.color
        let saturatedColor = ThemeColor.D1.color
        attributes.backgroundColor = lerp(focusAmount,
                                          color1: unsaturatedColor,
                                          color2: saturatedColor)

        // Lerp text between T1 and T2
        let saturatedTextColor = ThemeColor.T2.color
        let unsaturatedTextColor = ThemeColor.T3.color
        attributes.textColor = lerp(focusAmount,
                                    color1: saturatedTextColor,
                                    color2: unsaturatedTextColor)

        attributes.brightness = backgroundBrightness
        attributes.shouldShowTail = indexPath.section == 0
        attributes.bubbleTailOrientation = indexPath.section == 0 ? .up : .down
        attributes.detailAlpha = detailAlpha
        attributes.state = self.messageContentState

        return attributes
    }

    // MARK: - Attribute Helpers

    /// Returns a value between 0 and 1 denoting how in focus a section is. "In focus" means that its frontmost item is the one the user should
    /// be paying attention to..
    /// 0 means that no item in the section is even partially in focus.
    /// 1 means at least one item in the section is fully in focus, or we are between two items that are both partially in focus.
    func getFocusAmount(forSection section: SectionIndex) -> CGFloat {
        let focusPositionsInSection: [CGFloat] = self.itemFocusPositions
            .compactMap { (key: IndexPath, focusPosition: CGFloat) in
                if key.section == section {
                    return focusPosition
                }
                return nil
        }

        var normalizedDistance: CGFloat = 0

        for focusPosition in focusPositionsInSection {
            // Clamp the z position so items stay focused even when the user scrolls past the normal bounds.
            let clampedZPosition = clamp(self.zPosition, 0, self.maxZPosition)
            let itemDistance = abs(focusPosition - clampedZPosition)
            let normalizedItemDistance = itemDistance/self.itemHeight
            if normalizedItemDistance < 1 {
                normalizedDistance += 1 - normalizedItemDistance
            }
        }

        return normalizedDistance
    }

    func getBottomFrontmostCell() -> MessageCell? {
        guard let ip = self.getFrontmostIndexPath(in: 1),
              let cell = self.collectionView?.cellForItem(at: ip) as? MessageCell else {
                  return nil
              }
        return cell
    }

    func getDropZoneFrame() -> CGRect {
        let center = self.getItemCenterPoint(in: 1, withYOffset: 0, scale: 1)
        let padding = Theme.ContentOffset.short.value.doubled
        var frame = CGRect(x: padding.half,
                           y: 0,
                           width: self.collectionView!.width - padding,
                           height: MessageContentView.bubbleHeight - padding)
        frame.centerY = center.y - padding - Theme.ContentOffset.short.value
        return frame
    }

    private func getMostRecentItemContentOffset() -> CGPoint? {
        guard let mostRecentIndex = self.itemZRanges.max(by: { kvp1, kvp2 in
            return kvp1.value.lowerBound < kvp2.value.lowerBound
        })?.key else { return nil }

        guard let upperBound = self.itemZRanges[mostRecentIndex]?.upperBound else { return nil }
        return CGPoint(x: 0, y: upperBound)
    }

    private func getCenterOfItems() -> CGPoint {
        let topCenter = self.getItemCenterPoint(in: 0, withYOffset: 0, scale: 1.0)
        let bottomCenter = self.getItemCenterPoint(in: 1, withYOffset: 0, scale: 1.0)
        let center = CGPoint(x: topCenter.x, y: (topCenter.y + bottomCenter.y) / 2)
        return center
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
