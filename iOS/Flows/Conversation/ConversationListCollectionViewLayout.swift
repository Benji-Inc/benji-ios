//
//  ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation



protocol ConversationListCollectionViewLayoutDelegate: AnyObject {
    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              cidFor indexPath: IndexPath) -> ConversationId?
    func conversationListCollectionViewLayout(_ layout: ConversationListCollectionViewLayout,
                                              didUpdateCentered cid: ConversationId?)
}

/// A custom layout class for conversation collection views. It lays out its contents in a single horizontal row.
class ConversationListCollectionViewLayout: UICollectionViewFlowLayout {

    weak var delegate: ConversationListCollectionViewLayoutDelegate?
    private var previousCenteredCID: ConversationId?
    
    var sideItemAlpha: CGFloat = 0.3
    
    override class var layoutAttributesClass: AnyClass {
        return ConversationsMessagesCellAttributes.self
    }

    override init() {
        super.init()
        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.scrollDirection = .horizontal
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        self.sendCenterUpdateEventIfNeeded(withContentOffset: newBounds.origin)
        return true
    }

    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        let itemWidth: CGFloat = Theme.getPaddedWidth(with: collectionView.width)
        let itemHeight: CGFloat = collectionView.height - collectionView.adjustedContentInset.vertical
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: (collectionView.width - itemWidth).half,
                                                   bottom: 0,
                                                   right: (collectionView.width - itemWidth).half)

        self.sectionInset = .zero
        self.minimumLineSpacing = Theme.ContentOffset.standard.value
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        return attributes.map({ attribute in
            let copy = attribute.copy() as! ConversationsMessagesCellAttributes
            return self.transformLayoutAttributes(copy)
        })
    }
    
    private func transformLayoutAttributes(_ attributes: ConversationsMessagesCellAttributes) -> UICollectionViewLayoutAttributes {
        guard let collectionView = self.collectionView else { return attributes }
        let isHorizontal = (self.scrollDirection == .horizontal)

        let collectionCenter = isHorizontal ? collectionView.halfWidth : collectionView.halfHeight
        let offset = isHorizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y
        let normalizedCenter = (isHorizontal ? attributes.center.x : attributes.center.y) - offset

        let maxDistance = (isHorizontal ? self.itemSize.width : self.itemSize.height) + self.minimumLineSpacing
        let distance = min(abs(collectionCenter - normalizedCenter), maxDistance)
        let ratio = (maxDistance - distance)/maxDistance

        let alpha = ratio * (1 - self.sideItemAlpha) + self.sideItemAlpha

        attributes.alpha = alpha
        attributes.canScroll = alpha == 1.0

        return attributes
    }

    private func sendCenterUpdateEventIfNeeded(withContentOffset contentOffset: CGPoint) {
        var cid: ConversationId?
        if let centeredItem = self.getCenteredItem(forContentOffset: contentOffset) {
            cid = self.delegate?.conversationListCollectionViewLayout(self,
                                                                      cidFor: centeredItem.indexPath)
        }
        if self.previousCenteredCID != cid {
            self.previousCenteredCID = cid
            self.delegate?.conversationListCollectionViewLayout(self, didUpdateCentered: cid)
        }
    }

    // MARK: - Scrolling Behavior

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        guard let collectionView = self.collectionView else { return .zero }

        guard let centeredItem = self.getCenteredItem(forContentOffset: proposedContentOffset) else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }

        // Always scroll so that a cell is centered when we stop scrolling.
        let newXOffset = centeredItem.frame.centerX - collectionView.halfWidth

        return CGPoint(x: newXOffset, y: proposedContentOffset.y)
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        self.sendCenterUpdateEventIfNeeded(withContentOffset: proposedContentOffset)

        return self.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                        withScrollingVelocity: .zero)
    }

    /// Gets the UICollectionViewLayoutAttributes of the centermost item given the specified collection view  content offset.
    func getCenteredItem(forContentOffset contentOffset: CGPoint)
    -> UICollectionViewLayoutAttributes? {

        guard let collectionView = self.collectionView else { return nil }

        let targetRect = CGRect(x: contentOffset.x,
                                y: contentOffset.y,
                                width: collectionView.width,
                                height: collectionView.height)

        guard let layoutAttributes = self.layoutAttributesForElements(in: targetRect) else { return nil }

        var closestItemAttributes: UICollectionViewLayoutAttributes? = nil
        var closestOffset: CGFloat = .greatestFiniteMagnitude

        // Find the item whose center is closest to the proposed offset and set that as the new scroll target
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - contentOffset.x) < abs(closestOffset - contentOffset.x) {
                closestItemAttributes = elementAttributes
                closestOffset = possibleNewOffset
            }
        }

        return closestItemAttributes
    }
}
