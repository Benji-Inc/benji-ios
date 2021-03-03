//
//  CameraManager.swift
//  Benji
//
//  Created by Benji Dodgson on 10/13/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import UIKit

class FaceDetectionViewController: ImageCaptureViewController {
    var sequenceHandler = VNSequenceRequestHandler()

    @IBOutlet var faceView: FaceView!

    @Published var faceDetected = false

    var maxX: CGFloat = 0.0
    var midY: CGFloat = 0.0
    var maxY: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.maxX = self.view.bounds.maxX
        self.midY = self.view.bounds.midY
        self.maxY = self.view.bounds.maxY
    }

    override func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        super.captureOutput(output, didOutput: sampleBuffer, from: connection)
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace)

        do {
            try self.sequenceHandler.perform([detectFaceRequest],
                                             on: imageBuffer,
                                             orientation: .leftMirrored)
        } catch {

        }
    }
}
