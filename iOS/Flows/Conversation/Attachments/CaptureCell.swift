//
//  CaptureCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CaptureCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = AttachmentsCollectionViewDataSource.OptionType
    
    var currentItem: AttachmentsCollectionViewDataSource.OptionType?
    
    private let imageView = UIImageView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
        
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.B2.color
    }
    
    func configure(with item: AttachmentsCollectionViewDataSource.OptionType) {
        self.imageView.image = item.image
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.3
        self.imageView.centerOnXAndY()
    }
}
