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

class FaceDetectionViewController: ImageCaptureViewController {

    var segmentationRequest = VNGeneratePersonSegmentationRequest()
    var sequenceHandler = VNSequenceRequestHandler()

    @Published var faceDetected = false
    @Published var eyesAreClosed = false
    @Published var isSmiling = false

    // The Metal pipeline.
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!

    var currentColor: CIColor = .yellow

    // The Core Image pipeline.
    var ciContext: CIContext!
    var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }

    @IBOutlet weak var cameraView: MTKView! {
        didSet {
            guard self.metalDevice.isNil else { return }
            self.setupMetal()
            self.setupCoreImage()
        }
    }

    #if IOS
    lazy var colorPickerVC = ColorPickerViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addChild(viewController: self.colorPickerVC)

        self.colorPickerVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first else { return }

            switch first {
            case .color(let color):
                self.currentColor = color 
            }

        }.store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.colorPickerVC.view.height = 50
        self.colorPickerVC.view.expandToSuperviewWidth()
        self.colorPickerVC.view.pinToSafeAreaBottom()
    }
    #endif

    override func captureOutput(_ output: AVCaptureOutput,
                                didOutput sampleBuffer: CMSampleBuffer,
                                from connection: AVCaptureConnection) {
        super.captureOutput(output, didOutput: sampleBuffer, from: connection)
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace)

        do {
            try self.sequenceHandler.perform([detectFaceRequest, self.segmentationRequest],
                                             on: imageBuffer,
                                             orientation: .leftMirrored)

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

        let imageOptions =  NSMutableDictionary(object: NSNumber(value: 5) as NSNumber, forKey: CIDetectorImageOrientation as NSString)
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
