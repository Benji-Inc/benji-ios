//
//  ContextCueAddCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueAddCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = User
    
    var currentItem: User?
    
    let addView = AddView()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.addView)
    }
    
    func configure(with item: User) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.addView.squaredSize = self.contentView.height
        self.addView.centerOnXAndY()
    }
}
