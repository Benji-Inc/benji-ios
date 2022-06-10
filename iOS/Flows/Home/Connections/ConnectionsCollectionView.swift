//
//  ConnectionsCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConnectionsCollectionView: CollectionView {
    
    init() {
        super.init(layout: ConnectionsCollectionViewLayout())
        self.contentInset = UIEdgeInsets(top: 100,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
        self.showsVerticalScrollIndicator = false 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
