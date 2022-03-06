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
}
