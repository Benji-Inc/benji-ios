//
//  FrontPreviewVideoView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FrontPreviewVideoView: VideoPreviewView {
    
    var animationDidStart: CompletionOptional = nil
    var animationDidEnd: CompletionOptional = nil
    
    var animation = CABasicAnimation(keyPath: "strokeEnd")
    
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        let color = ThemeColor.D6.color.cgColor
        shapeLayer.fillColor = ThemeColor.clear.color.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 4
        shapeLayer.shadowColor = color
        shapeLayer.shadowRadius = 5
        shapeLayer.shadowOffset = .zero
        shapeLayer.shadowOpacity = 1.0
        return shapeLayer
    }()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        self.layer.cornerRadius = self.height * 0.25
    }
    
    func beginRecordingAnimation() {
    
        self.shapeLayer.removeFromSuperlayer()
        self.layer.addSublayer(self.shapeLayer)
        
        self.animation.delegate = self
        self.animation.fromValue = 0
        self.animation.duration = ExpressionViewController.maxDuration
        self.animation.isRemovedOnCompletion = false
        self.animation.fillMode = .forwards
        
        self.shapeLayer.path = UIBezierPath(roundedRect: self.bounds,
                                            byRoundingCorners: [.allCorners],
                                            cornerRadii: CGSize(width: self.height * 0.25, height: self.height * 0.25)).cgPath
    
        self.shapeLayer.add(self.animation, forKey: "MyAnimation")
    }
    
    func stopRecordingAnimation() {
        self.shapeLayer.removeFromSuperlayer()
        self.shapeLayer.removeAllAnimations()
    }
}

extension FrontPreviewVideoView: CAAnimationDelegate {
    
    func animationDidStart(_ anim: CAAnimation) {
        self.animationDidStart?()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.animationDidEnd?()
    }
}

