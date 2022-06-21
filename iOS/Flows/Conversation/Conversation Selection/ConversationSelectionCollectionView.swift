//
//  ConversationSelectionCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSelectionCollectionView: CollectionView {
    
    init() {
        super.init(layout: ConversationSelectionCollectionViewLayout())
        guard let window = UIWindow.topWindow() else { return }
        
        self.contentInset = UIEdgeInsets(top: 100,
                                         left: 0,
                                         bottom: window.halfHeight,
                                         right: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
