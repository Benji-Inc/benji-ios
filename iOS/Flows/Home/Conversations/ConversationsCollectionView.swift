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
        super.init(layout: ConverssationsCollectionViewLayout())
        
        let top = UIWindow.topWindow()?.safeAreaInsets.top ?? 0 + 46
        self.contentInset = UIEdgeInsets(top: top,
                                         left: 0,
                                         bottom: 100,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
