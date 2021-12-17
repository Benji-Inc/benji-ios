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

        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }

    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        let itemHeight: CGFloat = collectionView.height - collectionView.contentInset.vertical
        let itemWidth: CGFloat = Theme.getPaddedWidth(with: collectionView.width)
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: (collectionView.width - itemWidth).half,
                                                   bottom: 0,
                                                   right: (collectionView.width - itemWidth).half)

        // NOTE: Subtracting 1 to ensure there's enough vertical space for the cells.
        let verticalSpacing = clamp(collectionView.height - itemHeight - 1, min: 0)
        self.sectionInset = UIEdgeInsets(top: 0,
                                         left: 0,
                                         bottom: verticalSpacing,
                                         right: 0)
        self.minimumLineSpacing = Theme.ContentOffset.standard.value
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
