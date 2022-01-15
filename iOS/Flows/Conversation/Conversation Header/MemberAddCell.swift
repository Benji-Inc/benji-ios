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
    
    let addView = AddView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.addView)
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.addView.squaredSize = self.contentView.height
        self.addView.centerOnXAndY()
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        #warning("fix layout")
    }
}
