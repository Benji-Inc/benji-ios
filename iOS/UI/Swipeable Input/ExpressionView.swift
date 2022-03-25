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
        
    let label = ThemeLabel(font: .small)
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.layer.borderWidth = 0.5
                
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

        guard case .string(let emoji) = expressionJSON else {
            self.isVisible = false
            return
        }

        self.isVisible = true
        self.configure(for: emoji)
    }
    
    func configure(for emoji: String?) {
        if let e = emoji {
            self.label.setText(e)
        } else {
            self.label.setText("Say it...")
        }
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: 200)
        
        self.height = old_MessageDetailView.height
        
        self.width = self.label.width + Theme.ContentOffset.standard.value.doubled
        self.label.pin(.left, offset: .standard)
                
        self.pin(.left)
        
        self.label.centerOnY()
    }
}
