//
//  ConversationCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter
import StreamChat
import Combine

class ConversationCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = ConversationId
    
    var currentItem: ConversationId?
            
    let content = ConversationContentView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.content)
    }
    
    func configure(with item: ConversationId) {
        self.content.configure(with: item)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.content.expandToSuperviewSize()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.content.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.taskPool.cancelAndRemoveAll()
    }
}


