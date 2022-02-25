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
    let darkGradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight],
                                          startPoint: .topLeft, endPoint: .bottomRight)
    let lightGradientLayer = GradientLayer(with: [.L4TopLeft, .L4BottomRight],
                                           startPoint: .topLeft, endPoint: .bottomRight)
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.backgroundLayer.fillColor = ThemeColor.B0.color.cgColor
        self.layer.insertSublayer(self.backgroundLayer, below: self.bubbleLayer)

        self.darkGradientLayer.opacity = 0.2
        self.layer.insertSublayer(self.darkGradientLayer, above: self.bubbleLayer)

        self.lightGradientLayer.opacity = 0
        self.layer.insertSublayer(self.lightGradientLayer, above: self.bubbleLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        self.darkGradientLayer.frame = self.bubbleLayer.bounds
        self.lightGradientLayer.frame = self.bubbleLayer.bounds
        self.backgroundLayer.frame = self.bubbleLayer.bounds
        CATransaction.commit()
    }
    
    override func updateBubblePath() -> CGPath {
        let path = super.updateBubblePath()
        
        self.shapeMask.path = path
        
        self.backgroundLayer.path = path
        self.darkGradientLayer.mask = self.shapeMask
        self.lightGradientLayer.mask = self.shapeMask
        
        return path
    }
}
