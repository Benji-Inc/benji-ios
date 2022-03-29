//
//  EmotionCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCollectionView: CollectionView {
    
    init() {
        super.init(layout: EmotionsCollectionViewLayout())
        let padding = Theme.ContentOffset.xtraLong.value
        self.contentInset = UIEdgeInsets(top: padding,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
