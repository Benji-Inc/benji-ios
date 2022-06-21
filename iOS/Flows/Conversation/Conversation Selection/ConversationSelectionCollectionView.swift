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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
