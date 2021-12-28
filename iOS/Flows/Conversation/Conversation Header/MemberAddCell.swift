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
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.imageView)
        self.imageView.image = UIImage(systemName: "plus")
        self.imageView.tintColor = ThemeColor.white.color
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = self.contentView.height
        self.imageView.centerOnXAndY()
    }
}
