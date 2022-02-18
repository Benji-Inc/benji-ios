//
//  AchievementCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class AchievementCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = AchievementType
    
    var currentItem: AchievementType?
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.set(backgroundColor: .red)
    }
    
    func configure(with item: AchievementType) {
        self.currentItem = item
    }
}
