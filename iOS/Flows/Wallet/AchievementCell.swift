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
    
    private let badgeView = BadgeDetailView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.contentView.addSubview(self.badgeView)
    }
    
    func configure(with item: AchievementType) {
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
    
    func configure(with type: AchievementType) {
        self.badgeView.configure(with: type)
        self.label.setText(type.title)
        self.setNeedsLayout()
    }
}

private class BadgeView: BaseView {
    
    private let topView = BaseView()
    private let bottomView = BaseView()
    
    private let amountLabel = ThemeLabel(font: .mediumBold)
    private let imageView = UIImageView(image: UIImage(named: "jiblogo"))
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.topView)
        self.topView.addSubview(self.amountLabel)
        self.amountLabel.alpha = 0.5
        self.topView.set(backgroundColor: .badgeTop)
        self.topView.layer.cornerRadius = Theme.innerCornerRadius
        self.topView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        
        self.addSubview(self.bottomView)
        self.bottomView.set(backgroundColor: .badgeBottom)
        self.bottomView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        
        self.bottomView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.topView.height = self.halfHeight
        self.topView.expandToSuperviewWidth()
        self.topView.pin(.top)
        
        self.amountLabel.setSize(withWidth: self.width)
        self.amountLabel.centerOnXAndY()
        
        self.bottomView.height = self.halfHeight
        self.bottomView.expandToSuperviewWidth()
        self.bottomView.pin(.bottom)
        
        self.bottomView.layer.cornerRadius = self.halfWidth - Theme.ContentOffset.xtraLong.value

        self.imageView.squaredSize = 44
        self.imageView.centerOnXAndY()
    }
    
    func configure(with type: AchievementType) {
        self.amountLabel.setText("+\(type.bounty)")
        self.layoutNow()
    }
}
