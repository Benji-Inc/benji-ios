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

class LineDotView: BaseView {
    let lineView = BaseView()
    let circleView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .B1)
        self.lineView.width = 1.5
        
        self.addSubview(self.circleView)
        self.circleView.set(backgroundColor: .B1)
        self.circleView.layer.cornerRadius = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.width = 6
        
        self.lineView.height = self.height - 12.5
        self.lineView.pin(.top)
        self.lineView.centerOnX()
        
        self.circleView.squaredSize = self.width
        self.circleView.centerOnX()
        self.circleView.pin(.bottom, offset: .custom(12.5))
    }
}

class MessageSummaryView: BaseView {
    
    private var controller: MessageController?
        
    private let lineDotView = LineDotView()
    private let promptLabel = ThemeLabel(font: .smallBold, textColor: .D1)
    private let promptButton = ThemeButton()
    private let replyView = MessagePreview()
    
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((SuggestedReply) -> Void)? = nil
    var didSelectEmoji: ((String) -> Void)? = nil
    private var replyCount = 0
    private var totalUnreadReplyCount: Int = 0
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.replyView)
        self.replyView.isVisible = false
        
        self.addSubview(self.lineDotView)
        self.addSubview(self.promptLabel)
        self.addSubview(self.promptButton)
        self.promptButton.menu = self.addMenu()
        self.promptButton.didSelect { [unowned self] in
            self.didTapViewReplies?()
        }
    }
    
    /// The currently running task that is loading.
    private var loadTask: Task<Void, Never>?
    
    func configure(for message: Messageable) {
        guard let controller = ConversationsClient.shared.messageController(for: message) else { return }

        if let existing = self.controller,
            existing.messageId == controller.messageId,
            self.replyCount == controller.message?.replyCount,
            self.totalUnreadReplyCount == controller.message?.totalUnreadReplyCount {
            return
        }
        
        self.loadTask?.cancel()
        
        self.replyView.isVisible = false
        
        self.setPrompt(for: message)
        
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
            
            if let reply = self.controller?.message?.recentReplies.first {
                self.replyView.isVisible = true
                self.replyView.configure(with: reply)
            } else {
                self.replyView.isVisible = false
            }
            
            self.promptButton.showsMenuAsPrimaryAction = self.replyView.isHidden
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.layoutNow()
            })
        }
    }
    
    private func setPrompt(for message: Messageable) {
        // Remaining replies minus the one being displayed.
        let remainingReplyCount = clamp(message.totalReplyCount - 1, min: 0)
        self.totalUnreadReplyCount = message.totalUnreadReplyCount
        
        if message.totalReplyCount == 0 {
            self.promptLabel.setText("Reply")
        } else if remainingReplyCount == 0, self.totalUnreadReplyCount == 0 {
            self.promptLabel.setText("View thread")
        } else {
            if self.totalUnreadReplyCount == 1 {
                self.promptLabel.setText("View \(self.totalUnreadReplyCount) unread reply")
            } else if self.totalUnreadReplyCount > 1 {
                self.promptLabel.setText("View \(self.totalUnreadReplyCount) unread replies")
            } else if remainingReplyCount == 1 {
                self.promptLabel.setText("View \(remainingReplyCount) reply")
            } else {
                self.promptLabel.setText("View \(remainingReplyCount) more replies")
            }
        }
        
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.lineDotView.pin(.left)
        self.lineDotView.pin(.top)
        
        self.replyView.expandToSuperviewWidth()
        self.replyView.pin(.top, offset: .short)
        self.replyView.match(.left, to: .right, of: self.lineDotView, offset: .standard)
        
        if self.replyView.isVisible {
            self.height = self.replyView.height + 30 + Theme.ContentOffset.short.value
        } else {
            self.height = 30
        }
        
        self.promptLabel.setSize(withWidth: 200)
        self.promptLabel.match(.left, to: .right, of: self.lineDotView, offset: .standard)
        self.promptLabel.pin(.bottom, offset: .custom(8))
        
        self.promptButton.expandToSuperviewSize()
        
        self.lineDotView.expandToSuperviewHeight()
    }
    
    private func addMenu() -> UIMenu {
        
        var elements: [UIMenuElement] = []
        
        SuggestedReply.allCases.reversed().forEach { suggestion in
            
            if suggestion == .emoji {
                let reactionElements: [UIMenuElement] = suggestion.emojiReactions.compactMap { emoji in
                    return UIAction(title: emoji, image: nil) { [unowned self] _ in
                        self.didSelectEmoji?(emoji)
                    }
                }
                let reactionMenu = UIMenu(title: suggestion.text,
                                          image: suggestion.image,
                                          children: reactionElements)
                elements.append(reactionMenu)
                
            } else {
                let action = UIAction(title: suggestion.text, image: suggestion.image) { [unowned self] _ in
                    self.didSelectSuggestion?(suggestion)
                }
                elements.append(action)
            }
        }

        return UIMenu(title: "Suggestions", children: elements)
    }
}
