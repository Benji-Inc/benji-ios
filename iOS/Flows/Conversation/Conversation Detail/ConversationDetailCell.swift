//
//  ConversationDetailCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/21/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationDetailCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = ChannelId
    
    var currentItem: ChannelId?
    
    let imageView = UIImageView(image: UIImage(systemName: "person.badge.plus"))
    let rightImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    let label = ThemeLabel(font: .regular)
    let lineView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.T1.color
        
        self.contentView.addSubview(self.rightImageView)
        self.rightImageView.tintColor = ThemeColor.T1.color
        
        self.contentView.addSubview(self.label)

        self.contentView.addSubview(self.lineView)
        self.lineView.set(backgroundColor: .white)
        self.lineView.alpha = 0.1
    }
    
    func configure(with item: ChannelId) {}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 22
        self.imageView.centerOnY()
        self.imageView.pin(.left)
        
        self.rightImageView.squaredSize = 26
        self.rightImageView.centerOnY()
        self.rightImageView.pin(.right)
        
        self.label.setSize(withWidth: self.width)
        self.label.match(.left, to: .right, of: self.imageView, offset: .long)
        self.label.centerOnY()
        
        self.lineView.expandToSuperviewWidth()
        self.lineView.height = 1
        self.lineView.pin(.bottom)
    }
}

