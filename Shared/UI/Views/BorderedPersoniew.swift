//
//  BorderedAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCueView: BaseView {
    
    enum Size {
        case large
        case small
    }
    
    private let label = ThemeLabel(font: .systemSmall)
    var currentSize: Size = .small {
        didSet {
            self.label.setFont(self.currentSize == .small ? .systemSmall : .system)
            self.layoutNow()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.label)
        self.label.textAlignment = .center
        self.set(backgroundColor: .white)
        self.isHidden = true
    }
    
    private var newContextCueTask: Task<Void, Never>?
    
    func configure(with person: PersonType) {
        
        // Cancel any currently running swipe hint tasks so we don't trigger the animation multiple times.
        self.newContextCueTask?.cancel()
        
        self.newContextCueTask = Task { [weak self] in
            guard let user = person as? User,
                  let updated = try? await user.latestContextCue?.retrieveDataIfNeeded(),
                  let first = updated.emojis.first else {
                      self?.isHidden = true
                      return
                  }
            
            self?.isHidden = false
            self?.label.setText(first)
            self?.layoutNow()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.label.setSize(withWidth: self.height * 0.8)
        self.label.centerOnXAndY()
        
        self.squaredSize = self.currentSize == .small ? 22 : 30
        self.makeRound()
    }
}

class BorderedPersoniew: PersonView {
    
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
    
    let contextCueView = ContextCueView()

    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = false 
        
        self.layer.insertSublayer(self.shadowLayer, at: 0)
        self.layer.insertSublayer(self.pulseLayer, at: 2)
        
        self.addSubview(self.contextCueView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.cornerRadius = Theme.innerCornerRadius
        self.pulseLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: Theme.innerCornerRadius).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        
        self.contextCueView.pin(.right, offset: .negative(.short))
        self.contextCueView.pin(.bottom, offset: .negative(.short))
    }

    override func set(person: PersonType?) {
        super.set(person: person)

        guard let person = person else { return }
        self.setColors(for: person)
        self.contextCueView.configure(with: person)
    }

    override func didRecieveUpdateFor(person: PersonType) {
        super.didRecieveUpdateFor(person: person)
        self.setColors(for: person)
        self.contextCueView.configure(with: person)
    }
    
    private func setColors(for person: PersonType) {
        let isAvailable = person.focusStatus == .available
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
