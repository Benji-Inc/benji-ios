//
//  ReadSummaryView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReadSummaryView: BaseView, MessageConfigureable {
    
    private var controller: MessageController?
    private var readerCount: Int = 0
    
    let label = ThemeLabel(font: .small, textColor: .whiteWithAlpha)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        guard let controller = JibberChatClient.shared.messageController(for: message) else { return }

        if let existing = self.controller,
            existing.messageId == controller.messageId,
           self.readerCount == controller.message?.readReactions.count{
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
            
            self.readerCount = controller.message?.readReactions.count ?? 0
            
            if let reply = self.controller?.message?.recentReplies.first {
                //self.replyView.isVisible = true
               // self.replyView.configure(with: reply)
            } else {
               // self.replyView.isVisible = false
            }
                        
            await UIView.awaitAnimation(with: .fast, animations: {
                self.layoutNow()
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }
}
