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

    let imageView = UIImageView()
    let containerView = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.containerView)
        self.containerView.addSubview(self.imageView)
        self.imageView.image = UIImage(systemName: "plus")
        self.imageView.tintColor = ThemeColor.white.color
        
        self.containerView.set(backgroundColor: .textColor)
        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = Theme.innerCornerRadius
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.containerView.squaredSize = self.contentView.height
        self.containerView.centerOnXAndY()
        
        self.imageView.squaredSize = self.containerView.height * 0.5
        self.imageView.centerOnXAndY()
    }
}
