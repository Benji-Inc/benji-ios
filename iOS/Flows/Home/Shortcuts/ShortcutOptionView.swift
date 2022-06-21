//
//  ShortcutOptionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ShortcutOptionView: BaseView {
    
    static let height: CGFloat = 40
    
    private let selectionImpact = UIImpactFeedbackGenerator(style: .light)
    
    enum OptionType {
        case newMessage
        case addPeople
        case newVibe
        
        var symbol: ImageSymbol {
            switch self {
            case .newMessage:
                return .squareAndPencil
            case .addPeople:
                return .personBadgePlus
            case .newVibe:
                return .faceSmiling
            }
        }
        
        var text: String {
            switch self {
            case .newMessage:
                return "New Message"
            case .addPeople:
                return "Add People"
            case .newVibe:
                return "Update Vibe"
            }
        }
    }
    
    let imageView = SymbolImageView()
    let titleLabel = ThemeLabel(font: .regular)
    
    let type: OptionType
    
    var didSelectOption: ((OptionType) -> Void)? = nil
    
    init(with type: OptionType) {
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .D6)
                
        self.layer.borderColor = ThemeColor.D6.color.cgColor
        self.layer.borderWidth = Theme.borderWidth
        
        self.addSubview(self.imageView)
        self.imageView.set(symbol: self.type.symbol)
        self.imageView.tintColor = ThemeColor.white.color
        
        self.addSubview(self.titleLabel)
        self.titleLabel.setText(self.type.text)
        
        self.didSelect { [unowned self] in
            self.didSelectOption?(self.type)
            self.reset()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.makeRound()
        
        self.height = ShortcutOptionView.height
        
        self.imageView.squaredSize = 20
        self.imageView.pin(.left, offset: .long)
        self.imageView.centerOnY()
        
        self.titleLabel.setSize(withWidth: 200)
        self.titleLabel.match(.left, to: .right, of: self.imageView, offset: .standard)
        self.titleLabel.centerOnY()
        
        self.width = self.imageView.right + self.titleLabel.width + Theme.ContentOffset.long.value + Theme.ContentOffset.standard.value 
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        self.selectionImpact.impactOccurred()
        
        Task {
            await UIView.awaitAnimation(with: .fast, animations: {
                self.set(backgroundColor: .clear)
                self.imageView.tintColor = ThemeColor.D6.color
                self.titleLabel.setTextColor(.D6)
            })
        }
        
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        self.reset()
    }
    
    func reset() {
        Task {
            await UIView.awaitAnimation(with: .fast, animations: {
                self.set(backgroundColor: .D6)
                self.imageView.tintColor = ThemeColor.white.color
                self.titleLabel.setTextColor(.white)
            })
        }
    }
}
