//
//  RecentReplyView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class RecentReplyView: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Message
    
    var currentItem: Message?
    
    let titleLabel = ThemeLabel(font: .regular)
    let messageContent = MessageContentView()
    
    let middleBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)
    let bottomBubble = MessageBubbleView(orientation: .up, bubbleColor: .D1)

    private var controller: MessageController?
    
    var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.bottomBubble)
        self.contentView.addSubview(self.middleBubble)
        self.contentView.addSubview(self.messageContent)
        self.messageContent.layoutState = .collapsed
        
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
        
        self.messageContent.isVisible = false
        self.middleBubble.isVisible = false
        self.bottomBubble.isVisible = false
    }
    
    func configure(with item: Message) {
        Task.onMainActorAsync {
            
            if self.controller?.message != item {
                self.controller = ChatClient.shared.messageController(cid: item.cid!, messageId: item.id)

                try? await self.controller?.loadPreviousReplies()
                self.subscribeToUpdates()
            }
            
            guard !Task.isCancelled else { return }
            
            if let latest = self.controller?.replies.first {
                self.update(for: latest)
            }
        }
    }
    
    @MainActor
    private func update(for message: Message) {
        self.messageContent.configure(with: message)
        self.messageContent.isVisible = true
        self.middleBubble.isVisible = true
        self.bottomBubble.isVisible = true
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maxWidth = self.width - Theme.ContentOffset.xtraLong.value.doubled
        
        self.messageContent.width = maxWidth
        self.messageContent.height = MessageContentView.collapsedHeight
        self.messageContent.centerOnX()
        self.messageContent.pin(.top, offset: .custom(32))
        
        self.middleBubble.width = maxWidth * 0.8
        self.middleBubble.height = self.messageContent.height
        self.middleBubble.centerOnX()
        self.middleBubble.match(.bottom, to: .bottom, of: self.messageContent, offset: .standard)
        
        self.bottomBubble.width = maxWidth * 0.6
        self.bottomBubble.height = self.messageContent.height
        self.bottomBubble.centerOnX()
        self.bottomBubble.match(.bottom, to: .bottom, of: self.middleBubble, offset: .standard)
    }
    
    private func subscribeToUpdates() {
        
        self.subscriptions.forEach { cancellable in
            cancellable.cancel()
        }
        self.controller?
            .repliesChangesPublisher
            .mainSink { [unowned self] _ in
                guard let message = self.currentItem else { return }
                self.configure(with: message)
            }.store(in: &self.subscriptions)
    }
}
