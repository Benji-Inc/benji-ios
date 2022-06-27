//
//  MessageFooterDetailContainerView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageConfigureable {
    func configure(for message: Messageable)
}

class MessageFooterDetailContainerView: BaseView {
    
    enum State {
        case replies
        case expressions
    }
    
    let repliesView = RepliesCounterView()
    let expressionsView = ExpressionsCounterView()
    
    var didTapAddExpression: CompletionOptional = nil
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((String) -> Void)? = nil

    let replyButton = ThemeButton()
    
    @Published var state: State = .replies
            
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.replyButton.set(style: .image(symbol: .arrowTurnUpLeft, palletteColors: [.B0], pointSize: 12, backgroundColor: .white))
        self.replyButton.layer.cornerRadius = Theme.innerCornerRadius
        
        self.replyButton.menu = self.addMenu()
        self.replyButton.showsMenuAsPrimaryAction = true
        
        self.setupHandlers()
    }
    
    func configure(for message: Messageable) {
        
        self.removeAllSubviews()
        
        if message.parentMessageId.isNil {
            self.addSubview(self.repliesView)
            self.addSubview(self.expressionsView)
            self.addSubview(self.replyButton)
        } else {
            self.addSubview(self.expressionsView)
        }
        
        self.expressionsView.configure(for: message)
        self.repliesView.configure(for: message)
        
        self.layoutNow()
    }
    
    private func setupHandlers() {
                
        self.repliesView.$selectionState.mainSink { [unowned self] state in
            if state == .selected {
                self.expressionsView.selectionState = .normal
                self.state = .replies
            }
        }.store(in: &self.cancellables)
        
        self.expressionsView.$selectionState.mainSink { [unowned self] state in
            if state == .selected {
                self.repliesView.selectionState = .normal
                self.state = .expressions
            }
        }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.height = ImageCounterView.height
        
        if self.repliesView.superview.exists {
            self.repliesView.pin(.left)
            self.repliesView.pin(.top)
            
            self.expressionsView.match(.left, to: .right, of: self.repliesView, offset: .short)
            self.expressionsView.pin(.top)
            
            self.replyButton.size = CGSize(width: self.height * 1.75, height: self.height)
            self.replyButton.pin(.right)
            self.replyButton.pin(.top)
        } else {
            
            self.expressionsView.pin(.left)
            self.expressionsView.pin(.top)
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
        
        let action = UIAction(title: "Add expression", image: nil) { [unowned self] _ in
            self.didTapAddExpression?()
        }
        elements.append(action)
        

        return UIMenu(title: "Suggestions", children: elements)
    }
}
