//
//  ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A custom layout class for conversation collection views. It lays out its contents in a single horizontal row.
/// If the conversation collectionview's semantic content attribute is rightToLeft, the first cell will be on the far right.
class ConversationListCollectionViewLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // IMPORTANT: Returning true allows us to layout the cells right to left.
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
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
}