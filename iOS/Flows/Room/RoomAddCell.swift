//
//  RoomAddCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class RoomAddCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = [String]
    
    var currentItem: [String]?
    
    private let imageView = UIImageView()
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .B6)
        self.contentView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.T1.color.withAlphaComponent(0.8)
        self.contentView.addSubview(self.label)
        self.label.alpha = 0.25
        self.label.textAlignment = .center
        
        self.contentView.layer.borderColor = ThemeColor.BORDER.color.cgColor
        self.contentView.layer.borderWidth = 0.5
        self.contentView.layer.cornerRadius = Theme.cornerRadius
    }
    
    func configure(with item: [String]) {
        self.imageView.image = UIImage(systemName: "plus")
        self.label.setText("(\(item.count)) remaining")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.32
        self.imageView.centerOnXAndY()
        
        self.label.setSize(withWidth: self.contentView.width)
        self.label.centerOnX()
        self.label.match(.top, to: .bottom, of: self.imageView, offset: .standard)
    }
}
