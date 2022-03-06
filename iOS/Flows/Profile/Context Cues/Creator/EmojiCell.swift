//
//  EmojiCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = String
    
    var currentItem: String?
    
    private let label = ThemeLabel(font: .reactionEmoji)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.label)
    }
    
    func configure(with item: String) {
        self.label.setText(item)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
    }
}
