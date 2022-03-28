//
//  RecentReplyView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class RecentReplyView: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = MessageId
    
    var currentItem: MessageId?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        
    }
    
    func configure(with item: MessageId) {
        
    }
}
