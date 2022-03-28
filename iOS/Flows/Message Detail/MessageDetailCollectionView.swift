//
//  MessageDetailCollectionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageDetailCollectionView: CollectionView {
    
    init() {
        super.init(layout: MessageDetailCollectionViewLayout())
        self.set(backgroundColor: .red)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
