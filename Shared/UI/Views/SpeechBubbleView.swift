//
//  SpeechBubbleView.swift
//  Jibber
//
//  Created by Martin Young on 10/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

/// A view that has a rounded rectangular "speech bubble" background.
/// The bubble has two parts: The bubble itself, and a triangular "tail" positioned on one of four sides.
/// Subviews should be added to the contentView property.
class SpeechBubbleView: View {

    enum TailOrientation {
        case up
        case down
        case left
        case right
    }

    /// The direction that the speech bubble's tail is pointing.
    var orientation: TailOrientation {
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

    /// The color of the border around the speech bubble.
    var borderColor: UIColor? {
        get {
            guard let cgColor = self.bubbleLayer.strokeColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.bubbleLayer.strokeColor = newValue?.cgColor
        }
    }

    /// The distance from the base of the tail to the point.
    var tailLength: CGFloat = 10 {
        didSet { self.setNeedsLayout() }
    }
    /// The length of the base of the tail. In other words, side of the tail flush with bubble.
    var tailBaseLength: CGFloat = 8.6 {
        didSet { self.setNeedsLayout() }
    }
    /// Describes how much the bubble layer needs to be pushed in to make room for the tail.
    var bubbleFrame: CGRect {
        let topSide = self.orientation == .up ? self.tailLength : 0
        let leftSide = self.orientation == .left ? self.tailLength : 0
        let bottomSide = self.orientation == .down ? self.height - self.tailLength : self.height
        let rightSide = self.orientation == .right ? self.width - self.tailLength : self.width

        return CGRect(x: leftSide,
                      y: topSide,
                      width: rightSide - leftSide,
                      height: bottomSide - topSide)
    }

    /// The layer for drawing the speech bubble background.
    private let bubbleLayer = CAShapeLayer()

    init(orientation: TailOrientation, bubbleColor: UIColor? = nil, borderColor: UIColor? = nil) {
        self.orientation = orientation

        super.init()

        self.bubbleColor = bubbleColor
        self.borderColor = borderColor
    }

    required init?(coder aDecoder: NSCoder) {
        self.orientation = .down

        super.init(coder: aDecoder)

        self.bubbleColor = .clear
        self.borderColor = .white
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.bubbleLayer)
        self.bubbleLayer.lineWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.updateBubblePath()
    }

    /// Draws a path for the bubble and applies it to the bubble layer.
    private func updateBubblePath() {
        let cornerRadius: CGFloat = Theme.cornerRadius
        let bubbleFrame = self.bubbleFrame
        let tailBaseLength = self.tailBaseLength

        let path = CGMutablePath()

        // Top left corner
        path.move(to: CGPoint(x: bubbleFrame.left, y: bubbleFrame.top + cornerRadius))
        path.addArc(tangent1End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.top),
                    tangent2End: CGPoint(x: bubbleFrame.left + cornerRadius, y: bubbleFrame.top),
                    radius: cornerRadius)

        // Up facing tail
        if self.orientation == .up {
            path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: bubbleFrame.top))
            path.addLine(to: CGPoint(x: self.halfWidth, y: 0))
            path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: bubbleFrame.top))
        }

        // Top right corner
        path.addLine(to: CGPoint(x: bubbleFrame.right - cornerRadius, y: bubbleFrame.top))
        path.addArc(tangent1End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.top),
                    tangent2End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.top + cornerRadius),
                    radius: cornerRadius)

        // Right facing tail
        if self.orientation == .right {
            path.addLine(to: CGPoint(x: bubbleFrame.right, y: self.halfHeight - tailBaseLength.half))
            path.addLine(to: CGPoint(x: self.width, y: self.halfHeight))
            path.addLine(to: CGPoint(x: bubbleFrame.right, y: self.halfHeight + tailBaseLength.half))
        }

        // Bottom right corner
        path.addLine(to: CGPoint(x: bubbleFrame.right, y: bubbleFrame.bottom - cornerRadius))
        path.addArc(tangent1End: CGPoint(x: bubbleFrame.right, y: bubbleFrame.bottom),
                    tangent2End: CGPoint(x: bubbleFrame.right - cornerRadius, y: bubbleFrame.bottom),
                    radius: cornerRadius)

        // Down facing tail
        if self.orientation == .down {
            path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: bubbleFrame.bottom))
            path.addLine(to: CGPoint(x: self.halfWidth, y: self.height))
            path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: bubbleFrame.bottom))
        }

        // Bottom left corner
        path.addLine(to: CGPoint(x: bubbleFrame.left + cornerRadius, y: bubbleFrame.bottom))
        path.addArc(tangent1End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.bottom),
                    tangent2End: CGPoint(x: bubbleFrame.left, y: bubbleFrame.bottom - cornerRadius),
                    radius: cornerRadius)

        // Left facing tail
        if self.orientation == .left {
            path.addLine(to: CGPoint(x: bubbleFrame.left, y: self.halfHeight + tailBaseLength.half))
            path.addLine(to: CGPoint(x: 0, y: self.halfHeight))
            path.addLine(to: CGPoint(x: bubbleFrame.left, y: self.halfHeight - tailBaseLength.half))
        }

        path.closeSubpath()

        self.bubbleLayer.path = path
    }
}
