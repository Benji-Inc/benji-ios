//
//  EmotionView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import StreamChat

class EmotionView: View {
    
    let emojiContainer = View()
    let emojiLabel = Label(font: .small)
    
    let label = Label(font: .small)
    let button = Button()
    
    var didSelectEmotion: ((Emotion) -> Void)?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.emojiContainer)
        self.emojiContainer.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.emojiContainer.layer.cornerRadius = Theme.innerCornerRadius
        self.emojiContainer.layer.borderColor = Color.border.color.cgColor
        self.emojiContainer.layer.borderWidth = 0.25
        self.emojiContainer.addSubview(self.emojiLabel)
        
        self.addSubview(self.label)
        self.addSubview(self.button)
        
        self.clipsToBounds = true
        
        self.button.showsMenuAsPrimaryAction = true
    }
    
    func configure(for message: Messageable) {
        let controller = ChatClient.shared.messageController(for: message)
        if let msg = controller?.message, let reaction = msg.latestReactions.first(where: { reaction in
            return reaction.author.userObjectID == msg.authorID
        }), let emotion = Emotion(rawValue: reaction.type.rawValue) {
            self.isVisible = true
            self.configure(for: emotion)
        } else {
            self.isVisible = false
        }
    }
    
    func configure(for emotion: Emotion) {
        self.emojiLabel.text = emotion.emoji
        self.label.setText(emotion.rawValue.firstCapitalized)
        self.button.menu = self.createMenu(for: emotion)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: 200)
        
        self.emojiContainer.height = 20
        
        self.emojiLabel.sizeToFit()
        self.emojiContainer.width = self.emojiLabel.width + Theme.ContentOffset.short.value.doubled
        self.emojiLabel.centerOnXAndY()
        
        self.height = 20
        self.width = self.emojiContainer.width + Theme.ContentOffset.short.value + self.label.width + Theme.ContentOffset.short.value.doubled
        
        self.pin(.left)
        
        self.emojiContainer.pin(.left)
        self.emojiContainer.pin(.top)
        
        self.label.centerOnY()
        self.label.match(.left, to: .right, of: self.emojiContainer, offset: .short)
        
        self.button.expandToSuperviewSize()
    }
    
    private func createMenu(for emotion: Emotion) -> UIMenu {
        
        var children: [UIMenuElement] = []
        Emotion.allCases.forEach { e in
            let state: UIMenuElement.State = e == emotion ? .on : .off
            let title = "\(e.emoji) \(e.rawValue.capitalized)"
            let action = UIAction(title: title,
                                  image: nil,
                                  identifier: nil,
                                  discoverabilityTitle: nil,
                                  attributes: [],
                                  state: state) { [unowned self] _ in
                self.didSelectEmotion?(e)
                self.configure(for: e)
            }
            children.append(action)
        }
        
        return UIMenu(title: "I'm feeling...",
                      image: nil,
                      identifier: nil,
                      options: [.singleSelection],
                      children: children)
    }
}
