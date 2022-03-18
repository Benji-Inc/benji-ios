//
//  AttachementCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = Attachment
    
    var currentItem: Attachment?
    
    //private let label = ThemeLabel(font: .contextCues)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .red)
        
//        self.contentView.addSubview(self.label)
//        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
//        self.contentView.layer.borderWidth = 0.5
//        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(with item: Attachment) {
//        self.label.setText(item.emoji)
//        self.contentView.backgroundColor = item.isSelected ? ThemeColor.D6.color.withAlphaComponent(0.25) : ThemeColor.clear.color
//        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        self.label.setSize(withWidth: self.contentView.width)
//        self.label.centerOnXAndY()
    }
}
