//
//  CircleView.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class CircleView: BaseView {
    
    let avatarView = CircleAvatarView()
    var cancellables = Set<AnyCancellable>()
    
    lazy var shadowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.shadowColor = ThemeColor.B3.color.cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        return layer
    }()
    
    lazy var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = ThemeColor.B3.color.cgColor
        return layer
    }()
    
    lazy var dashedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineDashPattern = [4, 8]
        layer.lineWidth = 1.5
        layer.strokeColor = ThemeColor.D6.color.cgColor
        layer.fillColor = ThemeColor.B3.color.cgColor
        return layer
    }()
    
    enum State {
        case empty
        case contact
        case connection
    }
    
    @Published var uiState: State = .empty
    
    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.layer.addSublayer(self.shadowLayer)
        self.layer.addSublayer(self.circleLayer)
        self.layer.addSublayer(self.dashedLayer)
        
        self.avatarView.isHidden = true 
        
        self.addSubview(self.avatarView)
        self.clipsToBounds = false
        
        self.$uiState.mainSink { [unowned self] state in
            self.handle(state: state)
        }.store(in: &self.cancellables)
        
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.expandToSuperviewSize()
        
        var dashSize = self.size
        dashSize.height -= 2
        dashSize.width -= 2
        
        let dashOrigin = CGPoint(x: 1.0, y: 1.0)
        
        let dashBounds = CGRect(origin: dashOrigin, size: dashSize)
        
        self.circleLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath
        self.dashedLayer.path = UIBezierPath(ovalIn: dashBounds).cgPath
        self.shadowLayer.shadowPath = UIBezierPath(ovalIn: self.bounds).cgPath
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
