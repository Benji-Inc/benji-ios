//
//  MiniBadgeView.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MiniBadgeView: BaseView {
    
    private let topView = BaseView()
    private let bottomView = BaseView()
    
    private let amountLabel = ThemeLabel(font: .small, textColor: .white)
    private let imageView = UIImageView(image: UIImage(named: "Jib"))
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.topView)
        self.topView.addSubview(self.amountLabel)
        self.amountLabel.alpha = 0.5
        self.topView.set(backgroundColor: .badgeTop)
        self.topView.layer.cornerRadius = Theme.innerCornerRadius
        self.topView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        self.insertSubview(self.bottomView, at: 0)
        self.bottomView.set(backgroundColor: .B0)

        self.bottomView.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.topView.height = self.halfHeight
        self.topView.expandToSuperviewWidth()
        self.topView.pin(.top)
        
        self.amountLabel.setSize(withWidth: self.width)
        self.amountLabel.centerOnXAndY()
        
        self.bottomView.height = self.height
        self.bottomView.expandToSuperviewWidth()
        self.bottomView.pin(.bottom)
        
        self.bottomView.layer.cornerRadius = self.halfWidth
        
        self.imageView.squaredSize = self.bottomView.height * 0.6
        self.imageView.centerOnX()
        self.imageView.centerY = (self.height * 0.75)
    }
    
    func configure(with type: AchievementType) {
        self.amountLabel.setText("+\(type.bounty)")
        self.topView.set(backgroundColor: .badgeHighlightTop)
        self.bottomView.set(backgroundColor: .badgeHighlightBottom)
        self.amountLabel.alpha = 1.0
        self.layoutNow()
    }
}
