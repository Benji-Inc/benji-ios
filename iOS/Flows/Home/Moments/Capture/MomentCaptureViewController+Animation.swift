//
//  MomentCaptureViewController+Animation.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import QuartzCore

extension MomentCaptureViewController {
    
    func beginRecordingAnimation() {
    
        self.shapeLayer.removeFromSuperlayer()
        self.view.layer.addSublayer(self.shapeLayer)
        
        self.animation.delegate = self
        self.animation.fromValue = 0
        self.animation.duration = ExpressionViewController.maxDuration
        self.animation.isRemovedOnCompletion = false
        self.animation.fillMode = .forwards
        
        let containerView = self.expressionCaptureVC.faceCaptureVC.cameraViewContainer
        let frame = containerView.convert(containerView.bounds, to: self.view)
        self.shapeLayer.path = UIBezierPath(roundedRect: frame, byRoundingCorners: [.allCorners], cornerRadii: CGSize(width: frame.height * 0.25, height: frame.height * 0.25)).cgPath
    
        self.shapeLayer.add(self.animation, forKey: "MyAnimation")
    }
    
    func stopRecordingAnimation() {
        self.shapeLayer.removeFromSuperlayer()
        self.shapeLayer.removeAllAnimations()
    }
}

extension MomentCaptureViewController: CAAnimationDelegate {
    
    func animationDidStart(_ anim: CAAnimation) {
        self.expressionCaptureVC.faceCaptureVC.animate(text: "")
        self.expressionCaptureVC.beginVideoCapture()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if self.state == .capture {
            self.expressionCaptureVC.endVideoCapture()
        }
    }
}
