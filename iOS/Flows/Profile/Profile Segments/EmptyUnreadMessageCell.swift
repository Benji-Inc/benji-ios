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
    let label = ThemeLabel(font: .small)
        
    private var conversationController: ConversationController?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .center
        self.titleLabel.setText("You are all caught up! 🥳")
        
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0.25
        self.label.setText("Unread urgent messages will show here.")
    }
    
    private var loadConversationTask: Task<Void, Never>?
    
    func configure(with item: UserConversationsDataSource.ItemType) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.centerOnX()
        self.titleLabel.centerY = self.height * 0.4
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.width))
        self.label.pin(.bottom, offset: .standard)
        self.label.centerOnX()
    }
}
