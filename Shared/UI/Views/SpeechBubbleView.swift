//
//  SpeechBubbleView.swift
//  Jibber
//
//  Created by Martin Young on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class SpeechBubbleView: View {

    enum TailOrientation {
        case up
        case down
        case left
        case right
    }

    /// The direction that the speech bubble's tail is pointing.
    var orientation: TailOrientation = .down {
        didSet {
            self.setNeedsLayout()
        }
    }

    /// The color of the speech bubble.
    var bubbleColor: UIColor? {
        get {
            guard let cgColor = self.bubbleLayer.fillColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.bubbleLayer.fillColor = newValue?.cgColor
        }
    }
    var borderColor: UIColor? {
        get {
            guard let cgColor = self.bubbleLayer.strokeColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.bubbleLayer.strokeColor = newValue?.cgColor
        }
    }

    private let bubbleLayer = CAShapeLayer()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.bubbleLayer)
        self.bubbleLayer.lineWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        logDebug("hello")
        let path = CGMutablePath()
        let cornerRadius: CGFloat = Theme.cornerRadius

        let triangleHeight: CGFloat = 10
        let triangleSide: CGFloat = 8.6

        let topSide: CGFloat = self.orientation == .up ? triangleHeight : 0
        let bottomSide: CGFloat = self.orientation == .down ? self.height - triangleHeight : self.height
        let leftSide: CGFloat = self.orientation == .left ? triangleHeight : 0
        let rightSide: CGFloat = self.orientation == .right ? self.width - triangleHeight : self.width

        // Top left corner
        path.move(to: CGPoint(x: leftSide, y: topSide + cornerRadius))
        path.addArc(tangent1End: CGPoint(x: leftSide, y: topSide),
                    tangent2End: CGPoint(x: leftSide + cornerRadius, y: topSide),
                    radius: cornerRadius)

        // Up facing triangle
        if self.orientation == .up {
            path.addLine(to: CGPoint(x: self.halfWidth - triangleSide.half, y: topSide))
            path.addLine(to: CGPoint(x: self.halfWidth, y: 0))
            path.addLine(to: CGPoint(x: self.halfWidth + triangleSide.half, y: topSide))
        }

        // Top right corner
        path.addLine(to: CGPoint(x: rightSide - cornerRadius, y: topSide))
        path.addArc(tangent1End: CGPoint(x: rightSide, y: topSide),
                    tangent2End: CGPoint(x: rightSide, y: topSide + cornerRadius),
                    radius: cornerRadius)

        // Right facing triangle
        if self.orientation == .right {
            path.addLine(to: CGPoint(x: rightSide, y: self.halfHeight - triangleSide.half))
            path.addLine(to: CGPoint(x: self.width, y: self.halfHeight))
            path.addLine(to: CGPoint(x: rightSide, y: self.halfHeight + triangleSide.half))
        }

        // Bottom right corner
        path.addLine(to: CGPoint(x: rightSide, y: bottomSide - cornerRadius))
        path.addArc(tangent1End: CGPoint(x: rightSide, y: bottomSide),
                    tangent2End: CGPoint(x: rightSide - cornerRadius, y: bottomSide),
                    radius: cornerRadius)

        // Down facing triangle
        if self.orientation == .down {
            path.addLine(to: CGPoint(x: self.halfWidth + triangleSide.half, y: bottomSide))
            path.addLine(to: CGPoint(x: self.halfWidth, y: self.height))
            path.addLine(to: CGPoint(x: self.halfWidth - triangleSide.half, y: bottomSide))
        }

        // Bottom left corner
        path.addLine(to: CGPoint(x: leftSide + cornerRadius, y: bottomSide))
        path.addArc(tangent1End: CGPoint(x: leftSide, y: bottomSide),
                    tangent2End: CGPoint(x: leftSide, y: bottomSide - cornerRadius),
                    radius: cornerRadius)

        // Left facing triangle
        if self.orientation == .left {
            path.addLine(to: CGPoint(x: leftSide, y: self.halfHeight + triangleSide.half))
            path.addLine(to: CGPoint(x: 0, y: self.halfHeight))
            path.addLine(to: CGPoint(x: leftSide, y: self.halfHeight - triangleSide.half))
        }

        path.closeSubpath()

        self.bubbleLayer.path = path
    }
}
