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
    
    let middleBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)
    let bottomBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)
    
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
    
    private let stackedAvatarView = StackedAvatarView()
    
    private var conversationController: ConversationController?
    var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .white)
        self.lineView.alpha = 0.1
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.textAlignment = .left
        
        self.contentView.addSubview(self.bottomBubble)
        self.contentView.addSubview(self.middleBubble)
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
        
        self.middleBubble.setBubbleColor(bubbleColor, animated: false)
        self.middleBubble.lightGradientLayer.opacity
        = 0.8
        self.middleBubble.darkGradientLayer.opacity
        = 0.6
        self.middleBubble.tailLength = 0
        self.middleBubble.layer.masksToBounds = true
        self.middleBubble.layer.cornerRadius = Theme.cornerRadius
        
        self.bottomBubble.setBubbleColor(bubbleColor, animated: false)
        self.bottomBubble.lightGradientLayer.opacity
        = 0.4
        self.bottomBubble.darkGradientLayer.opacity
        = 0.2
        self.bottomBubble.layer.masksToBounds = true
        self.bottomBubble.layer.cornerRadius = Theme.cornerRadius
        self.bottomBubble.tailLength = 0
        
        self.contentView.addSubview(self.stackedAvatarView)
    }
    
    func configure(with item: ConversationId) {
        
        Task.onMainActorAsync {
            
            if self.conversationController?.cid != item {
                self.conversationController = ChatClient.shared.channelController(for: item)
                if let latest = self.conversationController?.channel?.latestMessages, latest.isEmpty  {
                    try? await self.conversationController?.synchronize()
                }
                
                let members = self.conversationController?.conversation.lastActiveMembers.filter { member in
                    return member.personId != ChatClient.shared.currentUserId
                } ?? []
                
                self.stackedAvatarView.configure(with: members)
                
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
        self.messageContent.height = MessageContentView.collapsedHeight
        self.messageContent.centerOnXAndY()
        
        self.middleBubble.width = maxWidth * 0.8
        self.middleBubble.height = self.messageContent.height
        self.middleBubble.centerOnX()
        self.middleBubble.match(.bottom, to: .bottom, of: self.messageContent, offset: .standard)
        
        self.bottomBubble.width = maxWidth * 0.6
        self.bottomBubble.height = self.messageContent.height
        self.bottomBubble.centerOnX()
        self.bottomBubble.match(.bottom, to: .bottom, of: self.middleBubble, offset: .standard)
        
        self.titleLabel.setSize(withWidth: self.width)
        self.titleLabel.match(.bottom, to: .top, of: self.messageContent, offset: .negative(.long))
        self.titleLabel.match(.left, to: .left, of: self.messageContent)
        
        self.stackedAvatarView.match(.right, to: .right, of: self.messageContent)
        self.stackedAvatarView.centerY = self.titleLabel.centerY
        
        self.leftLabel.setSize(withWidth: 120)
        self.leftLabel.match(.left, to: .left, of: self.bottomBubble)
        self.leftLabel.match(.top, to: .bottom, of: self.bottomBubble, offset: .long)
        
        self.rightLabel.sizeToFit()
        self.rightLabel.match(.right, to: .right, of: self.bottomBubble)
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

private class StackedAvatarView: BaseView {
    
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
    }
    
    func configure(with people: [PersonType]) {
        self.removeAllSubviews()
        
        for (index, person) in people.enumerated() {
            if index <= 2 {
                let view = BorderedPersonView()
                view.set(person: person)
                self.addSubview(view)
            }
        }
        
        if people.count > 3 {
            let remainder = people.count - 3
            self.label.setText("+\(remainder)")
            self.addSubview(self.label)
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = 22
        
        var xOffset: CGFloat = 0
        var count: Int = 0
        self.subviews.forEach { view in
            if let personView = view as? BorderedPersonView {
                personView.pulseLayer.borderWidth = 1
                personView.shadowLayer.opacity = 0.0
                personView.frame = CGRect(x: xOffset,
                                          y: 0,
                                          width: self.height,
                                          height: self.height)
                xOffset += view.width + Theme.ContentOffset.short.value
                count += 1
            }
        }
        
        xOffset -= Theme.ContentOffset.short.value
         
        if count == 3 {
            self.label.setSize(withWidth: 30)
            xOffset += self.label.width + Theme.ContentOffset.short.value
            self.label.centerOnY()
            self.label.right = xOffset
        }
        
        self.width = xOffset
    }
}
