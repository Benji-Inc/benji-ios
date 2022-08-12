//
//  BorderedAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class BorderedPersonView: PersonGradientView {
    
    let gradientLayer = GradientLayer(with: [.B0, .B6], startPoint: .topLeft, endPoint: .bottomRight)
    
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
        self.imageView.clipsToBounds = true
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        self.layer.insertSublayer(self.gradientLayer, at: 1)
        #if IOS
        self.addSubview(self.contextCueView)
        self.layer.insertSublayer(self.pulseLayer, below: self.contextCueView.layer)
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let cornerRadius = self.height * 0.25
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.cornerRadius = cornerRadius
        self.imageView.layer.cornerRadius = cornerRadius
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
        self.gradientLayer.frame = self.bounds
        self.gradientLayer.cornerRadius = cornerRadius
        #if IOS
        self.contextCueView.pin(.right, offset: .negative(.short))
        self.contextCueView.pin(.bottom, offset: .negative(.short))
        self.bringSubviewToFront(self.contextCueView)
        #endif
    }

    @MainActor
    
    override func set(expression: Expression? = nil, person: PersonType?) {
        super.set(expression: expression, person: person)
        
        guard let person = person else { return }
        
        #if IOS
        self.contextCueView.configure(with: person)
        #endif
        
        self.layer.borderWidth = 0 
        self.pulseLayer.borderColor = self.layer.borderColor
        self.shadowLayer.shadowColor = self.layer.borderColor
    }

    override func didRecieveUpdateFor(person: PersonType) {
        super.didRecieveUpdateFor(person: person)
        self.setColors(for: person)
        #if IOS
        self.contextCueView.configure(with: person)
        #endif
    }
    
    func setColors(for person: PersonType) {
        let isAvailable = person.focusStatus == .available
        let color = isAvailable ? ThemeColor.D6.color.cgColor : self.layer.borderColor

        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.pulseLayer.borderColor = color
            self.shadowLayer.shadowColor = color
        }
    }
    
    @MainActor
    override func set(image: UIImage?, state: State) async {
        await super.set(image: image, state: state)
        
        if image.isNil {
            self.shadowLayer.shadowColor = self.layer.borderColor
            self.pulseLayer.borderColor = self.layer.borderColor
            self.pulseLayer.borderWidth = 2
        }
    }
}
