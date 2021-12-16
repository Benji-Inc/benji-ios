//
//  ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol ConversationListCollectionViewLayoutDelegate: AnyObject {
    func conversationListCollectionViewLayoutDidUpdateCenterCell(_ layout: ConversationListCollectionViewLayout)
}

/// A custom layout class for conversation collection views. It lays out its contents in a single horizontal row.
class ConversationListCollectionViewLayout: UICollectionViewFlowLayout {

    weak var delegate: ConversationListCollectionViewLayoutDelegate?

    override init() {
        super.init()

        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        let itemHeight: CGFloat = collectionView.height
        let itemWidth: CGFloat = Theme.getPaddedWidth(with: collectionView.width)
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: (collectionView.width - itemWidth).half,
                                                   bottom: 0,
                                                   right: (collectionView.width - itemWidth).half)

        // NOTE: Subtracting 1 to ensure there's enough vertical space for the cells.
        let verticalSpacing = collectionView.height - itemHeight - 1
        self.sectionInset = UIEdgeInsets(top: 0,
                                         left: 0,
                                         bottom: verticalSpacing,
                                         right: 0)
        self.minimumLineSpacing = Theme.ContentOffset.standard.value
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {

        guard let collectionView = self.collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }

        // Always scroll so that a cell is centered when we stop scrolling.
        var newXOffset = CGFloat.greatestFiniteMagnitude
        let targetRect = CGRect(x: proposedContentOffset.x,
                                y: proposedContentOffset.y,
                                width: collectionView.width,
                                height: collectionView.height)

        guard let layoutAttributes = self.layoutAttributesForElements(in: targetRect) else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }

        // Find the item whose center is closest to the proposed offset and set that as the new scroll target
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - proposedContentOffset.x) < abs(newXOffset - proposedContentOffset.x) {
                newXOffset = possibleNewOffset
            }
        }

        self.delegate?.conversationListCollectionViewLayoutDidUpdateCenterCell(self)
        return CGPoint(x: newXOffset, y: proposedContentOffset.y)
    }
}
