//
//  MessageTopOptionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageTopOptionCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = MessageDetailDataSource.OptionType
    
    var currentItem: MessageDetailDataSource.OptionType?
    
    let imageView = UIImageView()
    let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.white.color
        self.contentView.addSubview(self.label)
        self.label.textAlignment = .center
        
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(with item: MessageDetailDataSource.OptionType) {
        self.imageView.image = item.image
        self.label.setText(item.title)
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.32
        self.imageView.centerOnX()
        self.imageView.bottom = self.contentView.centerY + 6
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.imageView, offset: .standard)
    }
}
