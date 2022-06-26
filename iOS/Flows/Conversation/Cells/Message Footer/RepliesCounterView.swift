//
//  RepliesCounterView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RepliesCounterView: ImageCounterView, MessageConfigureable {
    
    private var controller: MessageController?
    private var replyCount = 0
    private var totalUnreadReplyCount: Int = 0
    
    init() {
        super.init(with: .rectangleStack)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            
            if self.replyCount > 0 {
                self.viewState = .count(self.replyCount)
            } else {
                self.viewState = .empty
            }
        }
    }
}
