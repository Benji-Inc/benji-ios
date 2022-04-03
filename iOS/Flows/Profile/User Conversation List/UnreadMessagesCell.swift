//
//  UnreadMessagesCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/2/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter
import StreamChat
import Combine



class UnreadMessagesCell: CollectionViewManagerCell, ManageableCell {
    
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
                                         textColor: ThemeColor.T1.color,
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
        self.messageContent.layoutState = .collapsed
        
        self.contentView.addSubview(self.leftLabel)
        self.leftLabel.textAlignment = .left
        
        self.contentView.addSubview(self.rightLabel)
        
        let bubbleColor = ThemeColor.D1.color
        self.messageContent.configureBackground(color: bubbleColor,
                                                textColor: ThemeColor.T3.color,
                                                brightness: 1.0,
                                                showBubbleTail: false,
                                                tailOrientation: .up)
    }
    
    private var loadConversationTask: Task<Void, Never>?
    
    func configure(with item: ConversationId) {
        self.loadConversationTask?.cancel()
        
        self.loadConversationTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            if self.conversationController?.cid != item {
                self.conversationController = ChatClient.shared.channelController(for: item)
                if let latest = self.conversationController?.channel?.latestMessages, latest.isEmpty  {
                    try? await self.conversationController?.synchronize()
                }
                     
                if let conversation = self.conversationController?.conversation {
                    self.setNumberOfUnread(value: conversation.totalUnread)
                }
                self.subscribeToUpdates()
            }
            
            guard !Task.isCancelled else { return }
            
            if let latest = self.conversationController?.channel?.latestMessages.first(where: { message in
                return !message.isDeleted
            }) {
                self.update(for: latest)
            }
        }
    }
    
    private func setNumberOfUnread(value: Int) {
        let new = Float(value)
        guard new != self.rightLabel.currentValue else { return }
        self.rightLabel.setValue(new, animated: true)
    }
    
    @MainActor
    private func update(for message: Message) {
        self.messageContent.configure(with: message)
        self.leftLabel.setText(message.createdAt.getDaysAgoString())
        
        let title = self.conversationController?.conversation.title ?? "Untitled"
        let groupName = "Favorites  /"
        self.titleLabel.setTextColor(.T1)
        self.titleLabel.setText("\(groupName)  \(title)")
        self.titleLabel.add(attributes: [.foregroundColor: ThemeColor.T1.color.withAlphaComponent(0.35)], to: groupName)
        
        self.layoutNow()
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
        
        let maxWidth = self.width * 0.9
        
        self.messageContent.width = maxWidth
        self.messageContent.height = MessageContentView.collapsedHeight + Theme.ContentOffset.xtraLong.value
        self.messageContent.centerOnXAndY()
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.match(.bottom, to: .top, of: self.messageContent, offset: .negative(.long))
        self.titleLabel.match(.left, to: .left, of: self.messageContent)
        
        self.leftLabel.setSize(withWidth: 120)
        self.leftLabel.match(.left, to: .left, of: self.messageContent, offset: .long)
        self.leftLabel.match(.top, to: .bottom, of: self.messageContent, offset: .long)
        
        self.rightLabel.sizeToFit()
        self.rightLabel.match(.right, to: .right, of: self.messageContent, offset: .negative(.long))
        self.rightLabel.match(.top, to: .top, of: self.leftLabel)
        
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
