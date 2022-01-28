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
    
    lazy var dashedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineDashPattern = [4, 8]
        layer.lineWidth = 2
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.fillColor = ThemeColor.clear.color.cgColor
        return layer
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        
        self.layer.addSublayer(self.shadowLayer)
        self.layer.addSublayer(self.circleLayer)
        self.layer.addSublayer(self.dashedLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var dashSize = self.size
        dashSize.height -= 2
        dashSize.width -= 2
        
        let dashOrigin = CGPoint(x: 1.0, y: 1.0)
        
        let dashBounds = CGRect(origin: dashOrigin, size: dashSize)
        
        self.circleLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.dashedLayer.path = UIBezierPath(ovalIn: dashBounds).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
