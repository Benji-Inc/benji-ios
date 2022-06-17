//
//  NoticesCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NoticesCollectionView: CollectionView {
    
    init() {
        super.init(layout: NoticesCollectionViewLayout())
        
        guard let superview = UIWindow.topWindow() else { return }

        let offset = superview.height * 0.6 - 220
        self.contentInset = UIEdgeInsets(top: offset,
                                         left: 0,
                                         bottom: 0,
                                         right: 0)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
