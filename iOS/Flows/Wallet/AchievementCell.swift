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
    
    private let badgeView = BadgeView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.badgeView)
    }
    
    func configure(with item: AchievementType) {
        self.currentItem = item
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.xtraLong.value
        self.badgeView.width = self.contentView.width - padding.doubled
        self.badgeView.height = self.contentView.height - padding.doubled
        self.badgeView.centerOnXAndY()
    }
}

private class BadgeView: BaseView {
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.set(backgroundColor: .red)
    }
}
