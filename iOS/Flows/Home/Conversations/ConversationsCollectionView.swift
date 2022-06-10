//
//  ConversationsCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationsCollectionView: CollectionView {
    
    init() {
        super.init(layout: ConversationsCollectionViewLayout())
        
        self.contentInset = UIEdgeInsets(top: 100,
                                         left: 0,
                                         bottom: 120,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
