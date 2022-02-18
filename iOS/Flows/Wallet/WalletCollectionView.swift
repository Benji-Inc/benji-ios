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
        
        let topOffset = Theme.ContentOffset.xtraLong.value.doubled + 20
        
        self.contentInset = UIEdgeInsets(top: topOffset,
                                         left: 0,
                                         bottom: 0,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
