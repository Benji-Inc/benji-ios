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

class ExpressionView: BaseView {
        
    let imageView = UIImageView(image: UIImage(systemName: "face.smiling"))
    let label = ThemeLabel(font: .contextCues)
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .clear)
        
        self.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.white.color.withAlphaComponent(0.3)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.label)
        
        self.clipsToBounds = false
    }
    
    func configure(for message: Messageable) {
        let controller = ChatClient.shared.messageController(for: message)
        
        guard let data = controller?.message?.extraData["expression"] else {
            self.isVisible = false
            return
        }

        guard case .array(let JSONObjects) = data, let expressionJSON = JSONObjects.first else {
            self.isVisible = false
            return
        }

        guard case .string(let value) = expressionJSON, let emoji = EmojiCategory.allEmojis.first(where: { emoji in
            return emoji.emoji == value 
        }) else {
            self.isVisible = false
            return
        }

        self.isVisible = true
        self.configure(for: emoji)
    }
    
    func configure(for emoji: Emoji?) {
        if let e = emoji?.emoji {
            self.label.setText(e)
            self.label.isVisible = true
            self.imageView.isVisible = false
        } else {
            self.label.isVisible = false
            self.imageView.isVisible = true
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.imageView.squaredSize = self.width * 0.8
        self.imageView.centerOnXAndY()
    }
}
