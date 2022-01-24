//
//  MessageSpeechBubble.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MessageBubbleView: SpeechBubbleView {
    
    let shapeMask = CAShapeLayer()
    let backgroundLayer = CAShapeLayer()
    let gradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight], startPoint: .topLeft, endPoint: .bottomRight)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.backgroundLayer.fillColor = ThemeColor.B0.color.cgColor
        self.layer.insertSublayer(self.backgroundLayer, below: self.bubbleLayer)

        #warning("put this back to 0.2")
        self.gradientLayer.opacity = 1
        self.layer.insertSublayer(self.gradientLayer, above: self.bubbleLayer)
    }
    
    func configure(with message: Messageable) {
        CATransaction.begin()
        self.gradientLayer.updateColors(with: [.D4TopLeft, .D4BottomRight])
        CATransaction.commit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.bubbleLayer.bounds
        self.backgroundLayer.frame = self.bubbleLayer.bounds
        CATransaction.commit()
    }
    
    override func updateBubblePath() -> CGPath {
        let path = super.updateBubblePath()
        
        self.shapeMask.path = path
        
        self.backgroundLayer.path = path
        self.gradientLayer.mask = self.shapeMask
        
        return path
    }
}
