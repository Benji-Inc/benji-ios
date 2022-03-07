//
//  EmojiCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCollectionView: CollectionView {
    
    init() {
        super.init(layout: EmojiCollectionViewLayout())
        self.allowsMultipleSelection = false
        let padding = Theme.ContentOffset.xtraLong.value
        let topOffset = padding.doubled 
        self.contentInset = UIEdgeInsets(top: topOffset,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
