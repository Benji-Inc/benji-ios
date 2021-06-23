//
//  ProfilePhotoViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 6/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Vision
import MetalKit
import AVFoundation

class ProfilePhotoViewController: ViewController {

    // The Vision requests and the handler to perform them.
    private let requestHandler = VNSequenceRequestHandler()
    private var facePoseRequest: VNDetectFaceRectanglesRequest!
    private var segmentationRequest = VNGeneratePersonSegmentationRequest()

    @IBOutlet weak var cameraView: MTKView! {
        didSet {
            guard self.metalDevice == nil else { return }
            self.setupMetal()
            self.setupCoreImage()
            setupCaptureSession()
        }
    }

    // The Metal pipeline.
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!

    // The Core Image pipeline.
    var ciContext: CIContext!
    var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }

    // The capture session that provides video frames.
    var session: AVCaptureSession?

    // MARK: - ViewController LifeCycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.intializeRequests()
    }

    deinit {
        self.session?.stopRunning()
    }

    // MARK: - Prepare Requests

    private func intializeRequests() {

//        // Create a request to detect face rectangles.
//        facePoseRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
//            guard let face = request.results?.first as? VNFaceObservation else { return }
//            // Generate RGB color intensity values for the face rectangle angles.
//            self?.colors = AngleColors(roll: face.roll, pitch: face.pitch, yaw: face.yaw)
//        }
//        facePoseRequest.revision = VNDetectFaceRectanglesRequestRevision3
//
//        // Create a request to segment a person from an image.
//        segmentationRequest = VNGeneratePersonSegmentationRequest()
//        segmentationRequest.qualityLevel = .balanced
//        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    }

    func setupCaptureSession() {

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Error getting AVCaptureDeviceInput")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session = AVCaptureSession()
            self.session?.sessionPreset = .high
            self.session?.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: .main)

            self.session?.addOutput(output)
            output.connections.first?.videoOrientation = .portrait
            self.session?.startRunning()
        }
    }
}
