//
//  FaceDetectionViewController+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 1/18/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import UIKit

extension FaceDetectionViewController {

    func convert(rect: CGRect) -> CGRect {
        let origin = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        let size = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint)
        return CGRect(origin: origin, size: size.cgSize)
    }

    func landmark(point: CGPoint, to rect: CGRect) -> CGPoint {
        let absolute = point.absolutePoint(in: rect)
        let converted = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: absolute)
        return converted
    }

    func landmark(points: [CGPoint]?, to rect: CGRect) -> [CGPoint]? {
        guard let points = points else {
            return nil
        }

        return points.compactMap { self.landmark(point: $0, to: rect) }
    }

    func updateFaceView(for result: VNFaceObservation) {
        defer {
            self.faceView.setNeedsDisplay()
        }

        let box = result.boundingBox
        self.faceView.boundingBox = self.convert(rect: box)

        guard let landmarks = result.landmarks else { return }

        if let leftEye = self.landmark(points: landmarks.leftEye?.normalizedPoints,
                                       to: result.boundingBox) {
            self.faceView.leftEye = leftEye
        }

        if let rightEye = self.landmark( points: landmarks.rightEye?.normalizedPoints,
                                         to: result.boundingBox) {
            self.faceView.rightEye = rightEye
        }

        if let leftEyebrow = self.landmark(points: landmarks.leftEyebrow?.normalizedPoints,
                                           to: result.boundingBox) {
            self.faceView.leftEyebrow = leftEyebrow
        }

        if let rightEyebrow = self.landmark(points: landmarks.rightEyebrow?.normalizedPoints,
                                            to: result.boundingBox) {
            self.faceView.rightEyebrow = rightEyebrow
        }

        if let nose = self.landmark(points: landmarks.nose?.normalizedPoints,
                                    to: result.boundingBox) {
            self.faceView.nose = nose
        }

        if let outerLips = self.landmark(points: landmarks.outerLips?.normalizedPoints,
                                         to: result.boundingBox) {
            self.faceView.outerLips = outerLips
        }

        if let innerLips = self.landmark(points: landmarks.innerLips?.normalizedPoints,
                                         to: result.boundingBox) {
            self.faceView.innerLips = innerLips
        }

        if let faceContour = self.landmark(points: landmarks.faceContour?.normalizedPoints,
                                           to: result.boundingBox) {
            self.faceView.faceContour = faceContour
        }
    }

    func detectedFace(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let result = results.first else {
            self.faceView.clear()
            self.faceDetected = false
            return
        }

        self.updateFaceView(for: result)
        self.faceDetected = true
    }
}

private extension CGSize {
    var cgPoint: CGPoint {
        return CGPoint(x: self.width, y: self.height)
    }
}
