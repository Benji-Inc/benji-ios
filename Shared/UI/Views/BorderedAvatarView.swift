//
//  BorderedAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class BorderedAvatarView: AvatarView {
    
    let shadowLayer = CAShapeLayer()

    lazy var pulseLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.lineWidth = 1.5
        shape.lineCap = .round
        shape.fillColor = UIColor.clear.cgColor
        shape.cornerRadius = Theme.innerCornerRadius
        shape.borderColor = ThemeColor.D6.color.cgColor
        shape.borderWidth = 2
        return shape
    }()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false 
        
        self.layer.insertSublayer(self.pulseLayer, at: 2)
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        
        self.shadowLayer.shadowColor = ThemeColor.D6.color.cgColor
        self.shadowLayer.shadowOpacity = 0.35
        self.shadowLayer.shadowOffset = .zero
        self.shadowLayer.shadowRadius = 10
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Theme.innerCornerRadius).cgPath
        self.pulseLayer.position = self.imageView.center
        
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    }
    
    func beginTyping() {
        self.pulseLayer.removeAllAnimations()
        self.pulseLayer.strokeColor = ThemeColor.D6.color.cgColor
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.toValue = 1.2
        scale.fromValue = 1.0
        
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.toValue = 1.0
        fade.fromValue = 0.35
        
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.autoreverses = true
        group.repeatCount = .infinity
        
        self.pulseLayer.add(group, forKey: "pulsing")
    }

    func endTyping() {
        self.pulseLayer.strokeColor = ThemeColor.clear.color.cgColor
        self.pulseLayer.removeAllAnimations()
    }
}
