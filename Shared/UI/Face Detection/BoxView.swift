//
//  BoxView.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class BoxView: PassThroughView {
    
    private let maskLayer = CAShapeLayer() //create the mask layer
    
    var boundingBox: CGRect = .zero
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.alpha = 0
        
        self.backgroundColor = ThemeColor.T1.color.withAlphaComponent(0.6)
                
        // Fill rule set to exclude intersected paths
        self.maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        // By now the mask is a rectangle with a circle cut out of it. Set the mask to the view and clip.
        self.layer.mask = self.maskLayer
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let boxSize = CGSize(width: self.width * 0.9, height: self.width * 0.95)

        // Create a path with the rectangle in it.
        let path = UIBezierPath(rect: self.bounds)
        // Put a circle path in the middle
        var center = self.bounds.center
        center.y = center.y * 0.95
    
        var boxRect = CGRect(origin: .zero, size: boxSize)
        boxRect.center = center
        self.boundingBox = boxRect
        
        let topLeft = CGPoint(x: center.x - boxSize.width.half,
                              y: center.y - boxSize.width.half)
        let topRight = CGPoint(x: center.x + boxSize.width.half,
                               y: center.y - boxSize.width.half)
        let bottomRight = CGPoint(x: center.x + boxSize.width.half,
                                  y: center.y + boxSize.width.half)
        let bottomLeft = CGPoint(x: center.x - boxSize.width.half,
                                 y: center.y + boxSize.width.half)
    
        let radius = boxSize.width * 0.1
        
        path.move(to: CGPoint(x: topLeft.x + radius, y: topLeft.y))
        path.addLine(to: CGPoint(x: topRight.x - radius, y: topRight.y))
        path.addCurve(to: CGPoint(x: topRight.x,
                                  y: topRight.y + radius),
                      controlPoint1: topRight,
                      controlPoint2: topRight)
        path.addLine(to: CGPoint(x: bottomRight.x,
                                 y: bottomRight.y - radius))
        path.addCurve(to: CGPoint(x: bottomRight.x - radius,
                                  y: bottomRight.y),
                      controlPoint1: bottomRight,
                      controlPoint2: bottomRight)
        path.addLine(to: CGPoint(x: bottomLeft.x + radius,
                                 y: bottomLeft.y))
        path.addCurve(to: CGPoint(x: bottomLeft.x,
                                  y: bottomLeft.y - radius),
                      controlPoint1: bottomLeft,
                      controlPoint2: bottomLeft)
        path.addLine(to: CGPoint(x: topLeft.x,
                                 y: topLeft.y + radius))
        path.addCurve(to: CGPoint(x: topLeft.x + radius, y: topLeft.y),
                      controlPoint1: topLeft,
                      controlPoint2: topLeft)

        // Give the mask layer the path you just draw
        self.maskLayer.path = path.cgPath
    }
}
