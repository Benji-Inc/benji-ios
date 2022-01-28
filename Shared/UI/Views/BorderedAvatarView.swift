//
//  BorderedAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class BorderedAvatarView: AvatarView {
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.gray.color.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = .zero
        layer.shadowRadius = 6
        return layer 
    }()

    lazy var pulseLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 2
        layer.lineCap = .round
        layer.fillColor = UIColor.clear.cgColor
        layer.borderColor = ThemeColor.gray.color.cgColor
        layer.borderWidth = 2
        return layer
    }()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false 
        
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        self.layer.insertSublayer(self.pulseLayer, at: 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.cornerRadius = Theme.innerCornerRadius
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Theme.innerCornerRadius).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    }
    
    override func subscribeToUpdates(for user: User) {
        super.subscribeToUpdates(for: user)
        self.setColors(for: user)
    }
    
    override func didRecieveUpdateFor(user: User) {
        super.didRecieveUpdateFor(user: user)
        self.setColors(for: user)
    }
    
    private func setColors(for user: User) {
        let isAvailable = user.focusStatus == .available
        let color = isAvailable ? ThemeColor.D6.color.cgColor : ThemeColor.gray.color.cgColor
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.pulseLayer.borderColor = color
            self.shadowLayer.shadowColor = color 
        }
    }
    
    func beginTyping() {
        self.pulseLayer.removeAllAnimations()
        self.pulseLayer.strokeColor = self.pulseLayer.borderColor
        
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
