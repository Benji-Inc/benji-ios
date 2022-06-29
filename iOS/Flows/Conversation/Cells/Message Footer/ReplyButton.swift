//
//  ReplyButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class ReplyButton: BaseView {
    
    private var controller: MessageController?
    private var replyCount = 0
    private var totalUnreadReplyCount: Int = 0
    
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((String) -> Void)? = nil
    
    let button = ThemeButton()
    lazy var imageView = SymbolImageView(symbol: .arrowTurnUpLeft)
    
    let counter = NumberScrollCounter(value: 0,
                                      scrollDuration: Theme.animationDurationSlow,
                                      decimalPlaces: 0,
                                      prefix: "",
                                      suffix: nil,
                                      seperator: "",
                                      seperatorSpacing: 0,
                                      font: FontType.small.font,
                                      textColor: ThemeColor.B0.color,
                                      animateInitialValue: true,
                                      gradientColor: nil,
                                      gradientStop: nil)
    
    override func initializeSubviews() {
        super.initializeSubviews()
                
        self.layer.borderColor = ThemeColor.white.color.cgColor
        self.imageView.tintColor = ThemeColor.B0.color
        
        self.set(backgroundColor: .white)
        
        self.addSubview(self.imageView)
        self.imageView.setPoint(size: 10)
        
        self.addSubview(self.counter)
                
        self.addSubview(self.button)
        
        self.button.menu = self.addMenu()
        self.button.showsMenuAsPrimaryAction = true
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = MessageFooterView.collapsedHeight
        
        self.imageView.squaredSize = 18
        self.imageView.centerOnY()
        
        if self.counter.isHidden {
            self.width = self.height * 1.75
            self.imageView.centerOnX()
        } else {
            self.counter.sizeToFit()
            self.width = self.imageView.width + self.counter.width + Theme.ContentOffset.long.value.doubled 
            
            self.counter.pin(.right, offset: .standard)
            self.imageView.pin(.left, offset: .standard)
        }
        
        self.counter.centerY = self.imageView.centerY
        
        self.button.expandToSuperviewSize()
        
        self.makeRound()
        
        self.clipsToBounds = false
        self.showShadow(withOffset: 0, opacity: 0.5, radius: 5, color: ThemeColor.B0.color)
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
            self.counter.isVisible = self.replyCount > 0
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.layoutNow()
            })
            
            self.counter.setValue(Float(self.replyCount))
        }
    }
    
    private func addMenu() -> UIMenu {
        
        var elements: [UIMenuElement] = []
        
        SuggestedReply.allCases.reversed().forEach { suggestion in
            
            switch suggestion {
            case .quickReply:
                let quickElements: [UIMenuElement] = suggestion.quickReplies.compactMap { quick in
                    return UIAction(title: quick, image: nil) { [unowned self] _ in
                        self.didSelectSuggestion?(quick)
                    }
                }
                let quickMenu = UIMenu(title: suggestion.text,
                                          image: suggestion.image,
                                          children: quickElements)
                elements.append(quickMenu)
            case .emoji:
                let reactionElements: [UIMenuElement] = suggestion.emojiReactions.compactMap { emoji in
                    return UIAction(title: emoji, image: nil) { [unowned self] _ in
                        self.didSelectSuggestion?(emoji)
                    }
                }
                let reactionMenu = UIMenu(title: suggestion.text,
                                          image: suggestion.image,
                                          children: reactionElements)
                elements.append(reactionMenu)
            case .other:
                let action = UIAction(title: suggestion.text, image: suggestion.image) { [unowned self] _ in
                    self.didTapViewReplies?()
                }
                elements.append(action)
            }
        }
        

        return UIMenu(title: "Suggestions", children: elements)
    }
}
