//
//  D1GradientLayer.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class D1GradientLayer: CALayer {
    
    let backgroundLayer = CAShapeLayer()
    let gradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight], startPoint: .topLeft, endPoint: .bottomRight)
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func initializeSublayers() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.backgroundLayer.fillColor = ThemeColor.D1.color.cgColor
        self.insertSublayer(self.backgroundLayer, at: 0)
        self.insertSublayer(self.gradientLayer, at: 1)
        CATransaction.commit()
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        self.backgroundLayer.frame = self.bounds
        self.gradientLayer.frame = self.bounds
    }
}
