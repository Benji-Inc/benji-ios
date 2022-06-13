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
    
    private let imageView = SymbolImageView(symbol: .personBadgePlus)
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.D6.color.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = .zero
        layer.shadowRadius = 6
        return layer
    }()

    lazy var pulseLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 2
        layer.lineCap = .round
        layer.fillColor = ThemeColor.B6.color.cgColor
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.lineWidth = 2
        layer.lineDashPattern = [4, 8]
        return layer
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()
            
        self.contentView.layer.addSublayer(self.shadowLayer)
        self.contentView.layer.addSublayer(self.pulseLayer)
        
        self.contentView.addSubview(self.imageView)
        self.imageView.tintColor = ThemeColor.whiteWithAlpha.color
    }
    
    func configure(with item: String) {
        self.layoutNow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = self.contentView.height * 0.25
        
        self.imageView.squaredSize = self.contentView.height * 0.32
        self.imageView.centerOnXAndY()
        
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
    }
}
