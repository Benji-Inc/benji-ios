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
    
    let titleLabel = ThemeLabel(font: .regular)
    let messageContent = MessageContentView()
    
    let leftLabel = ThemeLabel(font: .small, textColor: .D1)
    let rightLabel = NumberScrollCounter(value: 0,
                                         scrollDuration: Theme.animationDurationSlow,
                                         decimalPlaces: 0,
                                         prefix: "Unread: ",
                                         suffix: nil,
                                         seperator: "",
                                         seperatorSpacing: 0,
                                         font: FontType.small.font,
                                         textColor: ThemeColor.D1.color,
                                         animateInitialValue: true,
                                         gradientColor: nil,
                                         gradientStop: nil)
    let lineView = BaseView()
    
    private var conversationController: ConversationController?
    var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
                
        self.contentView.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .white)
        self.lineView.alpha = 0.1
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .left
        
        self.contentView.addSubview(self.messageContent)
        
        self.contentView.addSubview(self.leftLabel)
        self.leftLabel.textAlignment = .left
        
        self.contentView.addSubview(self.rightLabel)
    }

    func configure(with item: ConversationId) {
        
        Task {
            
            if self.conversationController?.cid != item {
                self.conversationController = ChatClient.shared.channelController(for: item)
                if let latest = self.conversationController?.channel?.latestMessages, latest.isEmpty  {
                    try? await self.conversationController?.synchronize()
                }
                
                self.setNumberOfUnread(value: self.conversationController!.conversation.totalUnread)
                self.subscribeToUpdates()
            }
            
            guard !Task.isCancelled else { return }
            
            if let latest = self.conversationController?.channel?.latestMessages.first {
                self.update(for: latest)
            }
        }.add(to: self.taskPool)
    }
    
    private func setNumberOfUnread(value: Int) {
        let new = Float(value)
        guard new != self.rightLabel.currentValue else { return }
        self.rightLabel.setValue(new, animated: true)
    }
 
    private func update(for message: Message) {
        self.messageContent.configure(with: message)
        self.messageContent.configureBackground(color: ThemeColor.D1.color,
                                                textColor: ThemeColor.T2.color,
                                                brightness: 1.0,
                                                focusAmount: 1.0,
                                                showBubbleTail: false,
                                                tailOrientation: .up)
        self.leftLabel.setText(message.createdAt.getDaysAgoString())
        self.setNeedsLayout()
    }
    
    private func subscribeToUpdates() {
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversationController = self.conversationController else { return }
                self.setNumberOfUnread(value: conversationController.conversation.totalUnread)
            }.store(in: &self.subscriptions)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maxWidth = self.width * 0.75
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.pin(.top, offset: .xtraLong)
        self.titleLabel.pin(.left, offset: .custom(maxWidth * 0.5))
        
        self.messageContent.size = self.messageContent.getSize(for: .thread, with: maxWidth)
        self.messageContent.match(.top, to: .bottom, of: self.titleLabel, offset: .xtraLong)
        self.messageContent.match(.left, to: .left, of: self.titleLabel)
        
        self.leftLabel.setSize(withWidth: 120)
        self.leftLabel.right = self.contentView.halfWidth - Theme.ContentOffset.screenPadding.value
        self.leftLabel.centerOnY()
        
        self.rightLabel.sizeToFit()
        self.rightLabel.left = self.contentView.halfWidth + Theme.ContentOffset.screenPadding.value
        self.rightLabel.centerOnY()
        
        self.lineView.height = 1
        self.lineView.expandToSuperviewWidth()
        self.lineView.pin(.bottom)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.taskPool.cancelAndRemoveAll()
    }
}
