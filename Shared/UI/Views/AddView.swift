//
//  AddView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/15/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

private class AddGradientLayer: CAGradientLayer {
    
    override init() {
        
        let cgColors = [ThemeColor.B3.color.cgColor, ThemeColor.B3.color.withAlphaComponent(0).cgColor]
        
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

class AddView: BaseView {
    
    let imageView = UIImageView()
    
    private let gradientLayer = AddGradientLayer()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.imageView)
        self.set(backgroundColor: .B4)
        self.imageView.image = UIImage(systemName: "plus")
        self.imageView.tintColor = UIColor.white.withAlphaComponent(0.8)
        
        self.layer.borderColor = ThemeColor.B4.color.cgColor
        self.layer.borderWidth = 2
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Theme.innerCornerRadius
        
        self.gradientLayer.opacity = 0.2
        self.layer.insertSublayer(self.gradientLayer, at: 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageView.squaredSize = self.height * 0.5
        self.imageView.centerOnXAndY()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.bounds
        CATransaction.commit()
    }
}
