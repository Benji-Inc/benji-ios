//
//  PinnedMessageCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct PinModel: Hashable {
    var conversationId: String?
    var messageId: String?
}

class PinnedMessageCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = PinModel
    
    var currentItem: PinModel?
    let label  = ThemeLabel(font: .regular)
    let content = MessageContentView()
    // Context menu
    private lazy var contextMenuDelegate = MessageContentContextMenuDelegate(content: self.content)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0.25
        self.label.setText("No pinned messages")
        self.contentView.addSubview(self.content)
        
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
        self.content.bubbleView.addInteraction(contextMenuInteraction)
        self.content.bubbleView.setBubbleColor(ThemeColor.B6.color, animated: false)
    }
    
    func configure(with item: PinModel) {
        
        if let conversationId = item.conversationId, let messageId = item.messageId,
           let msg = ConversationsClient.shared.message(conversationId: conversationId, id: messageId) {
            self.content.configure(with: msg)
            self.content.isVisible = true
        } else {
            self.content.isVisible = false
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnXAndY()
        
        self.content.expandToSuperviewSize()
    }
    
}
