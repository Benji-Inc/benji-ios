//
//  EmptyUnreadMessageCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmptyUnreadMessagesCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = UserConversationsDataSource.ItemType
    
    var currentItem: UserConversationsDataSource.ItemType?
    
    let titleLabel = ThemeLabel(font: .regular)
        
    private var conversationController: ConversationController?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .center
        self.titleLabel.setText("You are all caught up! 🥳")
    }
    
    private var loadConversationTask: Task<Void, Never>?
    
    func configure(with item: UserConversationsDataSource.ItemType) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.centerOnXAndY()
    }
}
