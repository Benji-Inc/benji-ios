//
//  InitialsCircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InitialsCircleView: BaseView {
    
    let label = ThemeLabel(font: .mediumBold)
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.B3.color.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        return layer
    }()

    lazy var pulseLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.lineWidth = 1.5
        shape.lineCap = .round
        shape.fillColor = UIColor.clear.cgColor
        shape.borderColor = ThemeColor.D6.color.cgColor
        shape.borderWidth = 2
        return shape
    }()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false
        
        self.layer.insertSublayer(self.pulseLayer, at: 1)
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        
        self.addSubview(self.label)
        self.label.setText("BD")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.makeRound()
        
        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.pulseLayer.position = self.center
        
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
    }
}
