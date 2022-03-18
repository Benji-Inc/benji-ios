//
//  AttachementOptionCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AttachmentOptionCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = AttachmentsCollectionViewDataSource.OptionType
    
    var currentItem: AttachmentsCollectionViewDataSource.OptionType?
    
    private let imageView = UIImageView()
    private let label = ThemeLabel(font: .regular)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.T1.color
        
        self.contentView.addSubview(self.label)
    }
    
    func configure(with item: AttachmentsCollectionViewDataSource.OptionType) {
        self.imageView.image = item.image
        self.label.setText(item.title)
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = 20
        self.imageView.centerOnY()
        self.imageView.pin(.left)
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnY()
        self.label.match(.left, to: .right, of: self.imageView, offset: .long)
    }
}
