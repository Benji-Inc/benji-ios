//
//  ReplyButton.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ScrollCounter

class ReplyButton: ThemeButton {
    
    var didTapViewReplies: CompletionOptional = nil
    var didSelectSuggestion: ((String) -> Void)? = nil
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(style: .image(symbol: .arrowTurnUpLeft, palletteColors: [.B0], pointSize: 15, backgroundColor: .white))
        
        self.menu = self.addMenu()
        self.showsMenuAsPrimaryAction = true
        self.showShadow(withOffset: 0, opacity: 0.5, radius: 5, color: ThemeColor.B0.color)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = MessageFooterView.collapsedHeight
        self.width = self.height * 1.75
        
        self.makeRound()
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
