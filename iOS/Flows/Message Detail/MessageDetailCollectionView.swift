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
        self.set(backgroundColor: .B0)
        
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.cornerRadius = Theme.cornerRadius
        self.layer.masksToBounds = true 
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
