//
//  ReplyCountView.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/30/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization
import UIKit

class MessageSummaryView: BaseView, MessageConfigureable {
    
    private var controller: MessageController?
    let replyView = MessagePreview()
        
    private var replyCount = 0
    private var totalUnreadReplyCount: Int = 0
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.replyView)
        self.replyView.isVisible = false
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        guard let controller = JibberChatClient.shared.messageController(for: message) else { return }

        if let existing = self.controller,
            existing.messageId == controller.messageId,
            self.replyCount == controller.message?.replyCount,
            self.totalUnreadReplyCount == controller.message?.totalUnreadReplyCount {
            return
        }
        
        self.replyView.isVisible = false
        
        self.loadTask?.cancel()
                
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            guard !Task.isCancelled else { return }
            
            self.controller = controller
            
            if let controller = self.controller,
               controller.message!.replyCount > 0,
                !controller.hasLoadedAllPreviousReplies  {
                try? await controller.loadPreviousReplies()
            }
            
            self.replyCount = controller.message?.replyCount ?? 0
            self.totalUnreadReplyCount = message.totalUnreadReplyCount
            
            if let reply = self.controller?.message?.recentReplies.first {
                self.replyView.isVisible = true
                self.replyView.configure(with: reply)
            } else {
                self.replyView.isVisible = false
            }
                        
            await UIView.awaitAnimation(with: .fast, animations: {
                self.layoutNow()
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.replyView.expandToSuperviewSize()
    }
}
