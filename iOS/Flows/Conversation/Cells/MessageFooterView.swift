//
//  MessageFooterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

class MessageFooterView: BaseView {
    
    static let height: CGFloat = 25
    
    let stackedView = StackedPersonView()
    let replyCount = ReplyCountView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.stackedView)
        self.addSubview(self.replyCount)
    }
    
    func configure(for message: Messageable) {
        self.stackedView.configure(with: message.nonMeConsumers)
        self.replyCount.set(count: message.totalReplyCount)
        self.replyCount.isVisible = message.totalReplyCount > 0
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.stackedView.pin(.left)
        self.stackedView.centerOnY()
        
        self.replyCount.squaredSize = self.stackedView.height
        self.replyCount.pin(.right)
        self.replyCount.centerOnY()
    }
}
