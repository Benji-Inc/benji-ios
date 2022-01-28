//
//  EmptyCircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmptyCircleView: BaseView {
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.B3.color.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = .zero
        layer.shadowRadius = 6
        return layer
    }()
    
    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = ThemeColor.B3.color.withAlphaComponent(0.5).cgColor
        return layer
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        
        self.layer.addSublayer(self.shadowLayer)
        self.layer.addSublayer(self.circleLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.circleLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
