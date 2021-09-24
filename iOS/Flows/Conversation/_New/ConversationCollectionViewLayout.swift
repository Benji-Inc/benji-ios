//
//  new_ConversationCollectionViewLayout.swift
//  Jibber
//
//  Created by Martin Young on 9/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class new_ConversationCollectionViewLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        self.scrollDirection = .horizontal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        guard let collectionView = self.collectionView else { return }

        self.headerReferenceSize = CGSize(width: collectionView.width * 0.8,
                                          height: 200)
        
        let itemHeight: CGFloat = 200

        self.itemSize = CGSize(width: collectionView.width * 0.8, height: itemHeight)

        let verticalSpacing = (collectionView.height - itemHeight)
        self.sectionInset = UIEdgeInsets(top: verticalSpacing * 0.3,
                                         left: collectionView.width * 0.1,
                                         bottom: verticalSpacing * 0.7,
                                         right: collectionView.width * 0.1)
        self.minimumLineSpacing = collectionView.width * 0.05
    }
}
