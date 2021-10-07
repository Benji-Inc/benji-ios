//
//  new_ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

/// A custom layout class for conversation collection views. It lays out its contents in a single horizontal row.
/// If the conversation collectionview's semantic content attribute is rightToLeft, the first cell will be on the far right.
class new_ConversationCollectionViewLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // IMPORTANT: This allows us to layout the cells right to left.
    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
    
    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        collectionView.contentInset = UIEdgeInsets(top: 0,
                                                   left: collectionView.width * 0.1,
                                                   bottom: 0,
                                                   right: collectionView.width * 0.1)

        let itemHeight: CGFloat = 200

        self.itemSize = CGSize(width: collectionView.width * 0.8, height: itemHeight)

        let verticalSpacing = (collectionView.height - itemHeight)
        self.sectionInset = UIEdgeInsets(top: verticalSpacing * 0.2,
                                         left: 0,
                                         bottom: verticalSpacing * 0.8,
                                         right: 0)
        self.minimumLineSpacing = collectionView.width * 0.05
    }
}
