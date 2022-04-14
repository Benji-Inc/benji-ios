//
//  PinnedMessageCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct PinModel: Hashable {
    var cid: ConversationId?
    var messageId: MessageId?
}

class PinnedMessageCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = PinModel
    
    var currentItem: PinModel?
    let label  = ThemeLabel(font: .regular)
    let content = MessageContentView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0.25
        self.label.setText("No pinned messages")
        self.contentView.addSubview(self.content)
    }
    
    func configure(with item: PinModel) {
        
        if let cid = item.cid, let messageId = item.messageId,
           let msg = ChatClient.shared.message(cid: cid, id: messageId) {
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
