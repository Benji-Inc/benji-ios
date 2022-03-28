//
//  MessageMetadataCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageMetadataCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = Message
    
    var currentItem: Message?

    let label = ThemeLabel(font: .regular)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.label.setText("Coming soon...")
        self.label.alpha = 0.5
        self.contentView.addSubview(self.label)
    }
    
    func configure(with item: Message) {

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnXAndY()
    }
}
