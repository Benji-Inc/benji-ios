//
//  UnreadMessagesCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/2/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter
import Combine

struct UnreadMessagesModel: Hashable {
    var conversationId: String
    var messageIds: [String]
}

class UnreadMessagesCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = UnreadMessagesModel
    
    var currentItem: UnreadMessagesModel?
    
    let content = ConversationContentView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.content)
    }
    
    private var loadConversationTask: Task<Void, Never>?
    
    func configure(with item: UnreadMessagesModel) {
        self.content.configure(with: item.conversationId)
        
        if let _ = self.content.conversationController?.conversation?.messages.first(where: { message in
            return !message.isDeleted && message.canBeConsumed
        }).isNil {
            // do nothing
        } else {
            self.showError()
        }
    }
    
    func showError() {
        self.content.titleLabel.setText("You have 0 unread urgent messages.")
        self.content.messageContent.isVisible = false
        self.content.rightLabel.isVisible = false
        self.setNeedsLayout()
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
