//
//  MemberAddCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MemberAddCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = ChannelId
    
    var currentItem: ChannelId?
    
    private let imageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    private let label = ThemeLabel(font: .medium)
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.T1.color
        
        self.contentView.addSubview(self.label)
        self.label.setText("Add People")
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 26
        self.imageView.centerOnY()
        self.imageView.pin(.left)
        
        self.label.setSize(withWidth: self.width)
        self.label.match(.left, to: .right, of: self.imageView, offset: .long)
        self.label.centerOnY()
    }
}
