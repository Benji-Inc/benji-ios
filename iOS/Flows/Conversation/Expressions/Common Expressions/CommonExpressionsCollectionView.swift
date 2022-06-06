//
//  CommonExpressionsCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CommonExpressionsCollectionView: CollectionView {
    
    init() {
        super.init(layout: CommonExpressionsCollectionViewLayout())
        self.allowsMultipleSelection = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
