//
//  CalendarCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/5/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CalendarCollectionView: CollectionView {
    
    init() {
        super.init(layout: CalendarCollectionViewLayout())
        
        self.contentInset = UIEdgeInsets(top: 40 + Theme.ContentOffset.xtraLong.value,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
