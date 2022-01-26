//
//  CircleAvatarView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CircleAvatarView: BorderedAvatarView {
    
    enum State {
        case empty
        case contact
        case connection
    }
    
    @Published var uiState: State = .empty
    
    lazy var dashedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineDashPattern = [4, 6]
        layer.lineWidth = 1
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.fillColor = ThemeColor.clear.color.cgColor
        return layer
    }()
        
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.layer.addSublayer(self.dashedLayer)
        self.pulseLayer.isOpaque = true
        
        self.$uiState.mainSink { [unowned self] state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.makeRound()
        
        self.pulseLayer.frame = self.bounds
        self.pulseLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.pulseLayer.position = self.imageView.center
        
        self.dashedLayer.path = self.pulseLayer.path
        
        self.shadowLayer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
    }
    
    private func handle(state: State) {
        switch state {
        case .empty:
            // update border to be dashed lines
            break
        case .contact:
            // update border to reflect focus and show initials
            break
        case .connection:
            // update border to reflect focus and show image
            break
        }
    }
}
