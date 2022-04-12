//
//  BorderedAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class BorderedPersonView: PersonView {
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.B6.color.cgColor
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
        layer.borderColor = ThemeColor.B6.color.cgColor
        layer.borderWidth = 2
        return layer
    }()
    
    #if IOS
    let contextCueView = ContextCueView()
    #endif

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false 
        
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        self.layer.insertSublayer(self.pulseLayer, at: 2)
        #if IOS
        self.addSubview(self.contextCueView)
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.cornerRadius = Theme.innerCornerRadius
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Theme.innerCornerRadius).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        #if IOS
        self.contextCueView.pin(.right, offset: .negative(.short))
        self.contextCueView.pin(.bottom, offset: .negative(.short))
        #endif
    }

    @MainActor
    override func set(person: PersonType?) {
        super.set(person: person)

        guard let person = person else { return }
        
        self.setColors(for: person)
        #if IOS
        self.contextCueView.configure(with: person)
        #endif
    }

    override func didRecieveUpdateFor(person: PersonType) {
        super.didRecieveUpdateFor(person: person)
        self.setColors(for: person)
        #if IOS
        self.contextCueView.configure(with: person)
        #endif
    }
    
    private func setColors(for person: PersonType) {
        let isAvailable = person.focusStatus == .available
        let color = isAvailable ? ThemeColor.D6.color.cgColor : ThemeColor.yellow.color.cgColor

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
    
    @MainActor
    override func set(image: UIImage?, state: State) async {
        await super.set(image: image, state: state)
        
        if image.isNil {
            self.shadowLayer.shadowColor = ThemeColor.B6.color.cgColor
            self.pulseLayer.borderColor = ThemeColor.B6.color.cgColor
            self.pulseLayer.borderWidth = 2
        }
    }
}
