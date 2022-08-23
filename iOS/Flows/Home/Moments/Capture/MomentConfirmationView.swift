//
//  MomentConfirmationView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/23/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentConfirmationView: BaseView {
    
    let previewView = FrontPreviewVideoView()
    let circle = BaseView()
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.addSubview(self.circle)

        if let window = UIWindow.topWindow() {
            self.circle.squaredSize = window.height * 1.25
            self.circle.layer.cornerRadius = circle.halfHeight
        }
        
        self.circle.set(backgroundColor: .D1)
        self.circle.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        self.circle.alpha = 0
        
        self.addSubview(self.previewView)
        self.previewView.alpha = 0 
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.circle.centerOnXAndY()
        
        self.previewView.squaredSize = self.width * 0.2
        self.previewView.centerOnX()
        self.previewView.centerY = self.height * 0.25
        
    }
    
    func showCircle() async {
        await UIView.awaitSpringAnimation(with: .slow, animations: {
            self.circle.transform = .identity
            self.circle.alpha = 1.0 
        })
    }
}
