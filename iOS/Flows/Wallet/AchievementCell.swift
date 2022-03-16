//
//  AchievementCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/18/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct AchievementViewModel: Hashable {
    var type: AchievementType
    var count: Int = 0
}

class AchievementCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = AchievementViewModel
    
    var currentItem: AchievementViewModel?
    
    private let badgeView = BadgeDetailView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.badgeView)
    }
    
    func configure(with item: AchievementViewModel) {
        self.currentItem = item
        self.badgeView.configure(with: item)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let padding = Theme.ContentOffset.xtraLong.value
        self.badgeView.width = self.contentView.width - padding.doubled
        self.badgeView.height = self.contentView.height - padding.doubled
        self.badgeView.centerOnXAndY()
    }
}

private class BadgeDetailView: BaseView {
    
    private let badgeView = BadgeView()
    private let label = ThemeLabel(font: .small)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.badgeView)
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.label.alpha = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.badgeView.expandToSuperviewWidth()
        self.badgeView.height = self.height - 30
        self.badgeView.pin(.top)
        
        self.label.setSize(withWidth: self.width + 40)
        self.label.pin(.bottom)
        self.label.centerOnX()
    }
    
    func configure(with model: AchievementViewModel) {
        // get achievements for type
        self.badgeView.configure(with: model)
        self.label.setText(model.type.title)
        self.setNeedsLayout()
    }
}
