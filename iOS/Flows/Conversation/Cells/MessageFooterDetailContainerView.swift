//
//  MessageFooterDetailContainerView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageFooterDetailContainerView: BaseView {
    
    let repliesView = ImageCounterView(with: .rectangleStack)
    let expressionsView = ImageCounterView(with: .faceSmiling)
    let readView = ReadIndicatorView()
    
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((String) -> Void)? = nil

    let replyButton = ThemeButton()
            
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.repliesView)
        self.repliesView.$selectionState.mainSink { [unowned self] state in
            if state == .selected {
                self.expressionsView.selectionState = .normal
                self.readView.selectionState = .normal
                self.handleRepliesSelection()
            }
        }.store(in: &self.cancellables)
        
        self.addSubview(self.expressionsView)
        self.expressionsView.$selectionState.mainSink { [unowned self] state in
            if state == .selected {
                self.repliesView.selectionState = .normal
                self.readView.selectionState = .normal
                self.handleExpressionSelection()
            }
        }.store(in: &self.cancellables)
        
        self.addSubview(self.readView)
        self.readView.$selectionState.mainSink { [unowned self] state in
            if state == .selected {
                self.repliesView.selectionState = .normal
                self.expressionsView.selectionState = .normal
                self.handleReadSelection()
            }
        }.store(in: &self.cancellables)
        
        self.addSubview(self.replyButton)
        
        self.replyButton.set(style: .image(symbol: .arrowTurnUpLeft, palletteColors: [.B0], pointSize: 12, backgroundColor: .white))
        self.replyButton.layer.cornerRadius = Theme.innerCornerRadius
        
        self.replyButton.menu = self.addMenu()
        self.replyButton.showsMenuAsPrimaryAction = true 
    }
    
    func configure(for message: Messageable) {
        self.readView.configure(with: message)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = ImageCounterView.height
        
        self.repliesView.pin(.left)
        self.repliesView.pin(.top)
        
        self.expressionsView.match(.left, to: .right, of: self.repliesView, offset: .short)
        self.expressionsView.pin(.top)
        
        self.readView.match(.left, to: .right, of: self.expressionsView, offset: .short)
        self.readView.pin(.top)
        
        self.replyButton.size = CGSize(width: self.height * 1.75, height: self.height)
        self.replyButton.pin(.right)
        self.replyButton.pin(.top)
    }
    
    private func handleRepliesSelection() {
        
    }
    
    private func handleExpressionSelection() {
        
    }
    
    private func handleReadSelection() {
        
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
