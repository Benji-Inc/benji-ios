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

    var orientation: TailOrientation {
        get { return self.tailView.orientation }
        set {
            self.tailView.orientation = newValue
            self.setNeedsLayout()
        }
    }

    /// The color of the speech bubble.
    var bubbleColor: UIColor? {
        get {
            return self.bubbleView.backgroundColor
        }
        set {
            self.tailView.triangleColor = newValue
            self.bubbleView.backgroundColor = newValue
        }
    }
    var borderColor: UIColor? {
        get {
            guard let cgColor = self.bubbleView.layer.borderColor else { return nil }
            return UIColor(cgColor: cgColor)
        }
        set {
            self.bubbleView.layer.borderColor = newValue?.cgColor
            self.tailView.borderColor = newValue
        }
    }

    private let bubbleView = View()
    private let tailView = TriangleView(orientation: .down)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.bubbleView)
        self.addSubview(self.tailView)

        self.bubbleColor = Color.gray.color
        self.borderColor = Color.white.color
        self.bubbleView.layer.borderWidth = 2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.tailView.size = self.getTailSize()

        switch self.orientation {
        case .up:
            self.tailView.centerOnX()
            self.bubbleView.expandToSuperviewWidth()
            self.bubbleView.match(.top, to: .bottom, of: self.tailView)
            self.bubbleView.expand(.bottom)
        case .down:
            self.tailView.centerOnX()
            self.tailView.pin(.bottom)
            self.bubbleView.expandToSuperviewWidth()
            self.bubbleView.match(.bottom, to: .top, of: self.tailView, offset: 2)
            self.bubbleView.expand(.top)
        case .left:
            self.tailView.centerOnY()
            self.bubbleView.expandToSuperviewHeight()
            self.bubbleView.match(.left, to: .right, of: self.tailView)
            self.bubbleView.expand(.right)
        case .right:
            self.pin(.right)
            self.tailView.centerOnY()
            self.bubbleView.expandToSuperviewHeight()
            self.bubbleView.match(.left, to: .right, of: self.tailView)
            self.bubbleView.expand(.right)
        }

        self.bubbleView.roundCorners()
    }

    private func getTailSize() -> CGSize {
        switch self.orientation {
        case .up, .down:
            return CGSize(width: 10, height: 8.6)
        case .left, .right:
            return CGSize(width: 8.6, height: 10)
        }
    }
}

/// A view that displays a triangle within its bounds. The triangle is the color of the view's background color,
/// and  the rest of the view is always transparent.
private class TriangleView: View {

    /// The direction that the triangle should be pointing.
    var orientation: SpeechBubbleView.TailOrientation {
        didSet { self.setNeedsLayout() }
    }

    var triangleColor: UIColor? {
        get {
            return UIColor(cgColor: self.triangleLayer.strokeColor!)
        }
        set {
            self.triangleLayer.fillColor = newValue?.cgColor
        }
    }
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.triangleLayer.strokeColor!)
        }
        set {
            self.triangleLayer.strokeColor = newValue?.cgColor
        }
    }

    private let triangleLayer = CAShapeLayer()

    init(orientation: SpeechBubbleView.TailOrientation) {
        self.orientation = orientation

        super.init()

        self.triangleLayer.fillColor = UIColor.gray.cgColor
        self.triangleLayer.strokeColor = UIColor.white.cgColor
        self.triangleLayer.lineWidth = 2

        self.layer.addSublayer(self.triangleLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.updateMask()
    }

    private func updateMask() {

        let path = CGMutablePath()

        switch self.orientation {
        case .up:
            path.move(to: CGPoint(x: 0, y: self.height))
            path.addLine(to: CGPoint(x: self.halfWidth, y: 0))
            path.addLine(to: CGPoint(x: self.width, y: self.height))
        case .down:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: self.halfWidth, y: self.height))
            path.addLine(to: CGPoint(x: self.width, y: 0))
        case .left:
            path.move(to: CGPoint(x: self.width, y: 0))
            path.addLine(to: CGPoint(x: self.width, y: self.height))
            path.addLine(to: CGPoint(x: 0, y: self.halfHeight))
        case .right:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: self.width, y: self.halfHeight))
            path.addLine(to: CGPoint(x: 0, y: self.height))
        }

        self.triangleLayer.path = path
    }
}
