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
        
        self.backgroundLayer.fillColor = ThemeColor.BG.color.cgColor
        self.layer.insertSublayer(self.backgroundLayer, below: self.bubbleLayer)
        
        self.gradientLayer.opacity = 0.2
        self.layer.insertSublayer(self.gradientLayer, above: self.bubbleLayer)
    }
    
    func configure(with message: Messageable) {
        CATransaction.begin()
        
        if message.isFromCurrentUser {
            self.gradientLayer.updateColors(with: [.D4TopLeft, .D4BottomRight])
        } else {
            self.gradientLayer.updateColors(with: [.L4TopLeft, .L4BottomRight])
        }
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
