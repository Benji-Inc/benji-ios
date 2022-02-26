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
    
//    let middleBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)
//    let bottomBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)
    
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
        
//        self.contentView.addSubview(self.bottomBubble)
//        self.contentView.addSubview(self.middleBubble)
        self.messageContent.state = .thread
        self.contentView.addSubview(self.messageContent)
        
        self.contentView.addSubview(self.leftLabel)
        self.leftLabel.textAlignment = .left
        
        self.contentView.addSubview(self.rightLabel)
        
        let groupName = "Favorites  /"
        self.titleLabel.setText("\(groupName)  Josh & Erik")
        self.titleLabel.add(attributes: [.foregroundColor: ThemeColor.T1.color.withAlphaComponent(0.35)], to: groupName)
    }

    func configure(with item: ConversationId) {
        
        Task.onMainActorAsync {
            
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
        let bubbleColor = ThemeColor.D1.color
        self.messageContent.configureBackground(color: bubbleColor,
                                                textColor: ThemeColor.T3.color,
                                                brightness: 1.0,
                                                focusAmount: 1.0,
                                                showBubbleTail: false,
                                                tailOrientation: .up)
        self.leftLabel.setText(message.createdAt.getDaysAgoString())
        
//        self.middleBubble.setBubbleColor(bubbleColor, animated: false)
//        self.middleBubble.lightGradientLayer.opacity
//        = Float(1 - 1.0) * 0.2 * Float(1 - 0.6)
//        self.middleBubble.darkGradientLayer.opacity
//        = Float(1.0) * 0.2 * Float(1 - 0.6)
//        self.middleBubble.tailLength = 0
//
//        self.bottomBubble.setBubbleColor(bubbleColor, animated: false)
//        self.bottomBubble.lightGradientLayer.opacity
//        = Float(1 - 1.0) * 0.2 * Float(1 - 0.2)
//        self.bottomBubble.darkGradientLayer.opacity
//        = Float(1.0) * 0.2 * Float(1 - 0.2)
//        self.bottomBubble.tailLength = 0
        
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
        self.messageContent.height = MessageContentView.bubbleHeight - self.messageContent.bubbleView.tailLength - 4
        self.messageContent.centerOnXAndY()
        
//        self.middleBubble.width = maxWidth * 0.8
//        self.middleBubble.height = self.messageContent.height
//        self.middleBubble.centerOnX()
//        self.middleBubble.match(.bottom, to: .bottom, of: self.messageContent, offset: .short)
//
//        self.bottomBubble.width = maxWidth * 0.6
//        self.bottomBubble.height = self.messageContent.height
//        self.bottomBubble.centerOnX()
//        self.bottomBubble.match(.bottom, to: .bottom, of: self.middleBubble, offset: .short)
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.match(.bottom, to: .top, of: self.messageContent, offset: .negative(.long))
        self.titleLabel.match(.left, to: .left, of: self.messageContent)
        
        self.leftLabel.setSize(withWidth: 120)
        self.leftLabel.match(.left, to: .left, of: self.messageContent, offset: .screenPadding)
        self.leftLabel.match(.top, to: .bottom, of: self.messageContent, offset: .long)
        
        self.rightLabel.sizeToFit()
        self.rightLabel.match(.right, to: .right, of: self.messageContent, offset: .negative(.screenPadding))
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
