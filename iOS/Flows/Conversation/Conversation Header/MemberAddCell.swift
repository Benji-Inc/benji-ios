//
//  MemberAddCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MemberGradientLayer: CAGradientLayer {
    
    override init() {
        
        let cgColors = [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0).cgColor]
        
        super.init()
        self.startPoint = CAGradientLayer.Point.topLeft.point
        self.endPoint = CAGradientLayer.Point.bottomRight.point
        self.colors = cgColors
        self.type = .axial
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init()
    }
}

class MemberAddCell: CollectionViewManagerCell, ManageableCell {
    
    typealias ItemType = ChannelId
    
    var currentItem: ChannelId?

    let imageView = UIImageView()
    let containerView = BaseView()
    
    let gradientLayer = MemberGradientLayer()
    
    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.clipsToBounds = false
        self.contentView.addSubview(self.containerView)
        self.containerView.addSubview(self.imageView)
        self.containerView.set(backgroundColor: .B1)
        self.imageView.image = UIImage(systemName: "plus")
        self.imageView.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        self.containerView.layer.borderColor = ThemeColor.B1.color.cgColor
        self.containerView.layer.borderWidth = 2
        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = Theme.innerCornerRadius
        
        self.gradientLayer.opacity = 0.2
        self.containerView.layer.addSublayer(self.gradientLayer)
    }
    
    func configure(with item: ChannelId) {}

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.containerView.squaredSize = self.contentView.height
        self.containerView.centerOnXAndY()
        
        self.imageView.squaredSize = self.containerView.height * 0.5
        self.imageView.centerOnXAndY()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.containerView.bounds
        CATransaction.commit()
    }
}
