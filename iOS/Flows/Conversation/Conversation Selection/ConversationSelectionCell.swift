//
//  MemberSelectionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSelectionCell: CollectionViewManagerCell, ManageableCell {
    
    var currentItem: String?
    
    typealias ItemType = String

    let stackedPersonView = StackedPersonView()
    let titleLabel = ThemeLabel(font: .regular)
    private(set) var conversationController: ConversationController?
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.stackedPersonView.max = 5
        self.contentView.addSubview(self.stackedPersonView)
        self.contentView.addSubview(self.titleLabel)
    }
    
    func configure(with item: String) {
        
        Task.onMainActorAsync {
            let controller = JibberChatClient.shared.conversationController(for: item)
            
            if self.conversationController?.cid?.description != item,
               let conversation = controller?.conversation {
                self.conversationController = controller
                
                if conversation.latestMessages.isEmpty  {
                    try? await self.conversationController?.synchronize()
                }
                
                let members = conversation.lastActiveMembers.filter { member in
                    return member.personId != User.current()?.objectId
                }
                
                self.titleLabel.setText(conversation.description)
                self.stackedPersonView.configure(with: members)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedPersonView.pin(.right, offset: .xtraLong)
        self.stackedPersonView.centerOnY()
        
        let maxWidth = self.contentView.width - self.stackedPersonView.width - Theme.ContentOffset.xtraLong.value.doubled + Theme.ContentOffset.standard.value
        self.titleLabel.setSize(withWidth: maxWidth)
        self.titleLabel.match(.left, to: .right, of: self.stackedPersonView, offset: .standard)
        self.titleLabel.centerOnY()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.titleLabel.text = nil
    }
}
