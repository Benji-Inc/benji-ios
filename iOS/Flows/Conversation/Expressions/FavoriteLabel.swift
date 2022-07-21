//
//  FavoriteLabel.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FavoriteLabel: BaseView {
    
    private let emojiLabel = ThemeLabel(font: .small)
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.emojiLabel)
        self.addSubview(self.label)
    }
    
    func configure(with type: FavoriteType) {
        self.emojiLabel.setText(type.emoji)
        self.label.setText(type.emotion.description)
        self.label.textColor = type.emotion.color
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: 200)
        self.label.pin(.left)
        
        self.height = self.label.height
        
        self.label.centerOnY()
        
        self.emojiLabel.setSize(withWidth: 200)
        self.emojiLabel.match(.left, to: .right, of: self.label, offset: .short)
        self.emojiLabel.centerY = self.label.centerY
        
        self.width = self.emojiLabel.right
    }
}
