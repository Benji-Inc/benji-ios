//
//  ConversationCollectionView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/28/18.
//  Copyright © 2018 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ThreadCollectionView: CollectionView {

    let threadLayout = ThreadCollectionViewLayout()

    init() {
        super.init(layout: self.threadLayout)
        
        self.keyboardDismissMode = .interactive
        self.automaticallyAdjustsScrollIndicatorInsets = true 
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
