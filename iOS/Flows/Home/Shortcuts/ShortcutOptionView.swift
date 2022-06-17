//
//  ShortcutOptionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutOptionView: BaseView {
    
    static let height: CGFloat = 60
    
    enum OptionType {
        case newMessage
        case newConversation
        case newVibe
        
        var symbol: ImageSymbol {
            switch self {
            case .newMessage:
                return .plus
            case .newConversation:
                return .bolt
            case .newVibe:
                return .bell
            }
        }
        
        var text: String {
            switch self {
            case .newMessage:
                return "New Message"
            case .newConversation:
                return "New Conversation"
            case .newVibe:
                return "New Vibe"
            }
        }
    }
    
    let imageView = SymbolImageView()
    let titleLabel = ThemeLabel(font: .regular)
    
    let type: OptionType
    var didSelectOption: CompletionOptional = nil
    
    init(with type: OptionType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.imageView)
        self.imageView.set(symbol: self.type.symbol)
        self.imageView.tintColor = ThemeColor.white.color
        
        self.addSubview(self.titleLabel)
        self.titleLabel.setText(self.type.text)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.height = ShortcutOptionView.height
        
        self.imageView.squaredSize = 20
        self.imageView.pin(.left, offset: .long)
        self.imageView.centerOnY()
        
        self.titleLabel.setSize(withWidth: 200)
        self.titleLabel.match(.left, to: .right, of: self.imageView, offset: .standard)
        self.titleLabel.centerOnY()
        
        self.width = self.imageView.right + self.titleLabel.width + Theme.ContentOffset.standard.value.doubled
    }
}
