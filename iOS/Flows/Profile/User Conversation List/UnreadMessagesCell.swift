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

struct UnreadMessagesModel: Hashable {
    var cid: ConversationId
    var messageIds: [MessageId]
}

class UnreadMessagesCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = UnreadMessagesModel
    
    var currentItem: UnreadMessagesModel?
    
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
                                         textColor: ThemeColor.white.color,
                                         animateInitialValue: true,
                                         gradientColor: nil,
                                         gradientStop: nil)
    let lineView = BaseView()
    
    // Context menu
    private lazy var contextMenuDelegate = MessageContentContextMenuDelegate(content: self.messageContent)
        
    private var conversationController: ConversationController?
    var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
        self.messageContent.bubbleView.addInteraction(contextMenuInteraction)
        
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
        
        let bubbleColor = ThemeColor.B1.color
        self.messageContent.configureBackground(color: bubbleColor.withAlphaComponent(0.8),
                                                textColor: ThemeColor.white.color,
                                                brightness: 1.0,
                                                showBubbleTail: false,
                                                tailOrientation: .up)
        self.messageContent.blurView.effect = nil
    }
    
    private var loadConversationTask: Task<Void, Never>?
    
    func configure(with item: UnreadMessagesModel) {
        self.loadConversationTask?.cancel()
        
        self.loadConversationTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            if self.conversationController?.cid != item.cid {
                self.conversationController = ChatClient.shared.channelController(for: item.cid)
                if let latest = self.conversationController?.channel?.latestMessages, latest.isEmpty  {
                    try? await self.conversationController?.synchronize()
                }
                                     
                if let conversation = self.conversationController?.conversation {
                    self.setNumberOfUnread(value: conversation.totalUnread)
                } else {
                    self.showError()
                }
                
                self.subscribeToUpdates()
            }
            
            guard !Task.isCancelled else { return }
            
            if let latest = self.conversationController?.conversation?.messages.first(where: { message in
                return !message.isDeleted && message.canBeConsumed
            }) {
                self.update(for: latest)
            } else {
                self.showError()
            }
        }
    }
    
    private func setNumberOfUnread(value: Int) {
        let new = Float(value)
        guard new != self.rightLabel.currentValue else { return }
        self.rightLabel.setValue(new, animated: true)
    }
    
    @MainActor
    private func update(for message: Messageable) {
        self.messageContent.configure(with: message)
        self.leftLabel.setText(message.createdAt.getDaysAgoString())
        
        let title = self.conversationController?.conversation?.title ?? "Untitled"
        let groupName = "Favorites  /"
        self.titleLabel.setTextColor(.white)
        self.titleLabel.setText("\(groupName)  \(title)")
        self.titleLabel.add(attributes: [.foregroundColor: ThemeColor.white.color.withAlphaComponent(0.35)], to: groupName)
        
        self.layoutNow()
    }
    
    private func subscribeToUpdates() {
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        
        self.conversationController?
            .channelChangePublisher
            .mainSink(receiveValue: { [unowned self] _ in
                guard let conversation = self.conversationController?.conversation else { return }
                if let latest = conversation.latestMessages.first(where: { message in
                    return !message.isDeleted
                }) {
                    self.update(for: latest)
                }
                self.setNumberOfUnread(value: conversation.totalUnread)
            }).store(in: &self.subscriptions)
        
        self.conversationController?
            .messagesChangesPublisher
            .mainSink { [unowned self] changes in
                guard let conversation = self.conversationController?.conversation else { return }
                if let latest = conversation.latestMessages.first(where: { message in
                    return !message.isDeleted
                }) {
                    self.update(for: latest)
                }
                self.setNumberOfUnread(value: conversation.totalUnread)
            }.store(in: &self.subscriptions)
    }
    
    func showError() {
        self.titleLabel.setText("You have 0 unread urgent messages.")
        self.messageContent.isVisible = false
        self.rightLabel.isVisible = false
        self.leftLabel.isVisible = false 
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maxWidth = self.width

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
