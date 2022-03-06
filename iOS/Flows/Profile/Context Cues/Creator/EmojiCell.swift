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
    
    private let label = ThemeLabel(font: .systemLarge)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.label)
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        self.contentView.layer.shadowColor = ThemeColor.gray.color.cgColor
        self.contentView.layer.shadowOpacity = 0.35
        self.contentView.layer.shadowOffset = .zero
        self.contentView.layer.shadowRadius = 6
    }
    
    func configure(with item: Emoji) {
        self.label.setText(item.emoji)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnXAndY()
    }
    
    override func update(isSelected: Bool) {
        super.update(isSelected: isSelected)
        
        self.contentView.backgroundColor = isSelected ? ThemeColor.D6.color.withAlphaComponent(0.25) : ThemeColor.clear.color
    }
}
