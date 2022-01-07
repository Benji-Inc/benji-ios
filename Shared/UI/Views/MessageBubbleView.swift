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
    
    let gradientLayer = GradientLayer(with: [.D4TopLeft, .D4BottomRight], startPoint: .topLeft, endPoint: .bottomRight)
    
    override func initializeSubviews() {
        super.initializeSubviews()
                
        self.gradientLayer.opacity = 0.2
        self.layer.insertSublayer(self.gradientLayer, at: 2)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        self.gradientLayer.frame = self.bubbleLayer.bounds
        CATransaction.commit()
    }
    
    override func updateBubblePath() -> CGPath {
        let path = super.updateBubblePath()
        
        self.shapeMask.path = path
        self.gradientLayer.mask = self.shapeMask
        
        return path
    }
}
