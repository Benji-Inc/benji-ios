//
//  WalletCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class WalletCollectionView: CollectionView {
    
    init() {
        super.init(layout: WalletCollectionViewLayout())
        self.showsVerticalScrollIndicator = false
        
        let padding = Theme.ContentOffset.xtraLong.value
        let topOffset = padding.doubled + 20
        self.contentInset = UIEdgeInsets(top: topOffset,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
