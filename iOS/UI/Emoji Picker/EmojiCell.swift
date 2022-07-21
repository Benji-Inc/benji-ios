//
//  EmojiCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Emoji
    
    var currentItem: Emoji?
    
    private let label = ThemeLabel(font: .emoji)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.label)
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(with item: Emoji) {
        self.label.setText(item.emoji)
        self.contentView.backgroundColor = item.isSelected ? ThemeColor.D6.color.withAlphaComponent(0.25) : ThemeColor.clear.color
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnXAndY()
    }
}
