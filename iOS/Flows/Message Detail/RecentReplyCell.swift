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
import Lottie

struct RecentReplyModel: Hashable {
    var reply: Message?
    var isLoading: Bool
}

class RecentReplyCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = RecentReplyModel
    
    var currentItem: RecentReplyModel?
    
    let titleLabel = ThemeLabel(font: .regular)
    private let messageContent = MessageContentView()
    
    let animationView = AnimationView.with(animation: .loading)
    let label  = ThemeLabel(font: .regular)
    
    var subscriptions = Set<AnyCancellable>()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.animationView)
        self.animationView.loopMode = .loop
        self.contentView.addSubview(self.label)
        self.label.alpha = 0.25
        self.label.setText("No replies")
        
        self.contentView.addSubview(self.messageContent)
        self.messageContent.layoutState = .collapsed
        
        let bubbleColor = ThemeColor.B1.color
        self.messageContent.configureBackground(color: bubbleColor.withAlphaComponent(0.8),
                                                textColor: ThemeColor.white.color,
                                                brightness: 1.0,
                                                showBubbleTail: false,
                                                tailOrientation: .up)
        self.messageContent.blurView.effect = nil 
        self.messageContent.isVisible = false
        self.label.isVisible = false
    }
    
    func configure(with item: RecentReplyModel) {
        
        if let reply = item.reply {
            self.update(for: reply)
            self.animationView.stop()
        } else if !item.isLoading {
            self.label.isVisible = true
        }
    }
    
    private func update(for message: Message) {
        self.messageContent.configure(with: message)
        self.messageContent.isVisible = true
        self.label.isVisible = false
        self.animationView.stop()
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnXAndY()
        
        self.animationView.size = CGSize(width: 18, height: 18)
        self.animationView.centerOnXAndY()
        
        let maxWidth = self.width - Theme.ContentOffset.xtraLong.value.doubled
        
        self.messageContent.width = maxWidth
        self.messageContent.height = MessageContentView.collapsedHeight + Theme.ContentOffset.xtraLong.value
        self.messageContent.centerOnX()
        self.messageContent.pin(.top, offset: .custom(32))
    }
}
