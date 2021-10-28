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
    var tailHeight: CGFloat = 10 {
        didSet { self.setNeedsLayout() }
    }
    /// The length of the base of the tail. In other words, side of the tail flush with bubble.
    var tailBaseLength: CGFloat = 8.6 {
        didSet { self.setNeedsLayout() }
    }
    /// Describes how much bubble layer needs to be pushed in to make room for the tail.
    private var bubbleInsets: UIEdgeInsets {
        return UIEdgeInsets(top: self.orientation == .up ? self.tailHeight : 0,
                            left: self.orientation == .left ? self.tailHeight : 0,
                            bottom: self.orientation == .down ? self.height - self.tailHeight : self.height,
                            right: self.orientation == .right ? self.width - self.tailHeight : self.width)
    }

    /// A view to contain subviews you want positioned inside the bubble. This view matches the frame of the bubble, excluding the tail.
    let contentView = View()
    /// The layer for drawing the speech bubble background.
    private let bubbleLayer = CAShapeLayer()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.layer.addSublayer(self.bubbleLayer)
        self.bubbleLayer.fillColor = UIColor.gray.cgColor
        self.bubbleLayer.lineWidth = 2

        self.addSubview(self.contentView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.updateBubblePath()

        let bubbleInsets = self.bubbleInsets
        // Match the content view to the area of the bubble layer.
        self.contentView.left = bubbleInsets.left
        self.contentView.top = bubbleInsets.top
        self.contentView.expand(.right, to: bubbleInsets.right)
        self.contentView.expand(.bottom, to: bubbleInsets.bottom)
    }

    /// Draws a path for the bubble and applies it to the bubble layer.
    private func updateBubblePath() {
        let cornerRadius: CGFloat = Theme.cornerRadius
        let insets = self.bubbleInsets
        let tailBaseLength = self.tailBaseLength

        let path = CGMutablePath()

        // Top left corner
        path.move(to: CGPoint(x: insets.left, y: insets.top + cornerRadius))
        path.addArc(tangent1End: CGPoint(x: insets.left, y: insets.top),
                    tangent2End: CGPoint(x: insets.left + cornerRadius, y: insets.top),
                    radius: cornerRadius)

        // Up facing tail
        if self.orientation == .up {
            path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: insets.top))
            path.addLine(to: CGPoint(x: self.halfWidth, y: 0))
            path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: insets.top))
        }

        // Top right corner
        path.addLine(to: CGPoint(x: insets.right - cornerRadius, y: insets.top))
        path.addArc(tangent1End: CGPoint(x: insets.right, y: insets.top),
                    tangent2End: CGPoint(x: insets.right, y: insets.top + cornerRadius),
                    radius: cornerRadius)

        // Right facing tail
        if self.orientation == .right {
            path.addLine(to: CGPoint(x: insets.right, y: self.halfHeight - tailBaseLength.half))
            path.addLine(to: CGPoint(x: self.width, y: self.halfHeight))
            path.addLine(to: CGPoint(x: insets.right, y: self.halfHeight + tailBaseLength.half))
        }

        // Bottom right corner
        path.addLine(to: CGPoint(x: insets.right, y: insets.bottom - cornerRadius))
        path.addArc(tangent1End: CGPoint(x: insets.right, y: insets.bottom),
                    tangent2End: CGPoint(x: insets.right - cornerRadius, y: insets.bottom),
                    radius: cornerRadius)

        // Down facing tail
        if self.orientation == .down {
            path.addLine(to: CGPoint(x: self.halfWidth + tailBaseLength.half, y: insets.bottom))
            path.addLine(to: CGPoint(x: self.halfWidth, y: self.height))
            path.addLine(to: CGPoint(x: self.halfWidth - tailBaseLength.half, y: insets.bottom))
        }

        // Bottom left corner
        path.addLine(to: CGPoint(x: insets.left + cornerRadius, y: insets.bottom))
        path.addArc(tangent1End: CGPoint(x: insets.left, y: insets.bottom),
                    tangent2End: CGPoint(x: insets.left, y: insets.bottom - cornerRadius),
                    radius: cornerRadius)

        // Left facing tail
        if self.orientation == .left {
            path.addLine(to: CGPoint(x: insets.left, y: self.halfHeight + tailBaseLength.half))
            path.addLine(to: CGPoint(x: 0, y: self.halfHeight))
            path.addLine(to: CGPoint(x: insets.left, y: self.halfHeight - tailBaseLength.half))
        }

        path.closeSubpath()

        self.bubbleLayer.path = path
    }
}
