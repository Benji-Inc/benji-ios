//
//  FaceView.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Vision
import UIKit

class FaceView: UIView {

    var leftEye: [CGPoint] = []
    var rightEye: [CGPoint] = []
    var leftEyebrow: [CGPoint] = []
    var rightEyebrow: [CGPoint] = []
    var nose: [CGPoint] = []
    var outerLips: [CGPoint] = []
    var innerLips: [CGPoint] = []
    var faceContour: [CGPoint] = []

    var boundingBox = CGRect.zero

    func clear() {
        self.leftEye = []
        self.rightEye = []
        self.leftEyebrow = []
        self.rightEyebrow = []
        self.nose = []
        self.outerLips = []
        self.innerLips = []
        self.faceContour = []

        self.boundingBox = .zero

        Task.onMainActor {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()

        defer {
            context.restoreGState()
        }

        context.strokePath()

        Color.white.color.withAlphaComponent(0.5).setStroke()

        if !self.leftEye.isEmpty {
            context.addLines(between: self.leftEye)
            context.closePath()
            context.strokePath()
        }

        if !self.rightEye.isEmpty {
            context.addLines(between: self.rightEye)
            context.closePath()
            context.strokePath()
        }

        if !self.leftEyebrow.isEmpty {
            context.addLines(between: self.leftEyebrow)
            context.strokePath()
        }

        if !self.rightEyebrow.isEmpty {
            context.addLines(between: self.rightEyebrow)
            context.strokePath()
        }

        if !self.nose.isEmpty {
            context.addLines(between: self.nose)
            context.strokePath()
        }

        if !self.outerLips.isEmpty {
            context.addLines(between: self.outerLips)
            context.closePath()
            context.strokePath()
        }

        if !self.innerLips.isEmpty {
            context.addLines(between: self.innerLips)
            context.closePath()
            context.strokePath()
        }

        if !self.faceContour.isEmpty {
            context.addLines(between: self.faceContour)
            context.strokePath()
        }
    }
}

