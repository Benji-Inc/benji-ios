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
import MetalKit
import CoreImage.CIFilterBuiltins

class MetalView: MTKView {

    var context: CIContext
    var commandQueue: MTLCommandQueue

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        let dev = device ?? MTLCreateSystemDefaultDevice()!
        self.context = CIContext(mtlDevice: dev, options: [.cacheIntermediates : false])
        self.commandQueue = dev.makeCommandQueue()!

        super.init(frame: frameRect, device: dev)

        self.isPaused = true
        self.enableSetNeedsDisplay = false
        self.framebufferOnly = false
        self.isOpaque = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FaceDetectionViewController: ImageCaptureViewController {

    var segmentationRequest = VNGeneratePersonSegmentationRequest()
    var sequenceHandler = VNSequenceRequestHandler()

    @Published var faceDetected = false
    @Published var eyesAreClosed = false
    @Published var isSmiling = false

    var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }

    lazy var cameraView: MetalView = {
        let metalView = MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.delegate = self
        return metalView
    }()
    
    let orientation: CGImagePropertyOrientation = .left
        
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.cameraView)
        self.view.addSubview(self.boxView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.boxView.expandToSuperviewSize()
        
        self.cameraView.expandToSuperviewSize()
    }

    override func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        super.captureOutput(output, didOutput: sampleBuffer, from: connection)
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace)

        do {
            try self.sequenceHandler.perform([detectFaceRequest, self.segmentationRequest],
                                             on: imageBuffer,
                                             orientation: self.orientation)

            // Get the pixel buffer that contains the mask image.
            guard let maskPixelBuffer =
                    segmentationRequest.results?.first?.pixelBuffer else { return }
            // Process the images.
            self.blend(original: imageBuffer, mask: maskPixelBuffer)

        } catch {

        }
    }

    func detectedFace(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let _ = results.first else {
            self.faceDetected = false
            return
        }

        self.faceDetected = true
    }

    override func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        guard let connection = output.connection(with: .video) else { return }
        connection.automaticallyAdjustsVideoMirroring = true

        guard let ciImage = self.currentCIImage else { return }

        let image = UIImage(ciImage: ciImage, scale: 1.0, orientation: .up)

        let imageOptions = NSMutableDictionary(object: NSNumber(value: 5) as NSNumber, forKey: CIDetectorImageOrientation as NSString)
        imageOptions[CIDetectorEyeBlink] = true
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: ciImage, options: imageOptions as? [String : AnyObject])

        if let face = faces?.first as? CIFaceFeature {
            self.eyesAreClosed = face.leftEyeClosed && face.rightEyeClosed
            self.isSmiling = face.hasSmile
        } else {
            self.eyesAreClosed = false
            self.isSmiling = false 
        }


        self.didCapturePhoto?(image)
    }
}
