//
//  MemberAddCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MemberAddCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = String
    
    var currentItem: String?
    
    private let imageView = UIImageView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.white.color.withAlphaComponent(0.8)
        
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(with item: String) {
        self.imageView.image = ImageSymbol.plus.image
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.32
        self.imageView.centerOnXAndY()
    }
}
