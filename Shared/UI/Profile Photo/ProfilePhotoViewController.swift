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
import CoreImage.CIFilterBuiltins

class ProfilePhotoViewController: UIViewController, Presentable, Dismissable {

    func toPresentable() -> DismissableVC {
        return self
    }

    var dismissHandlers: [DismissHandler] = []
    
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

    // A structure that contains RGB color intensity values.
    private var colors: AngleColors?

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }

    deinit {
        self.session?.stopRunning()
    }

    // MARK: - Prepare Requests

    private func intializeRequests() {
        // Create a request to detect face rectangles.
        self.facePoseRequest = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            guard let face = request.results?.first as? VNFaceObservation else { return }
            // Generate RGB color intensity values for the face rectangle angles.
            self?.colors = AngleColors(roll: face.roll, pitch: face.pitch, yaw: face.yaw)
        }
        self.facePoseRequest.revision = VNDetectFaceRectanglesRequestRevision3

        // Create a request to segment a person from an image.
        self.segmentationRequest = VNGeneratePersonSegmentationRequest()
        self.segmentationRequest.qualityLevel = .balanced
        self.segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
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

    // MARK: - Perform Requests

    func processVideoFrame(_ framePixelBuffer: CVPixelBuffer) {
        // Perform the requests on the pixel buffer that contains the video frame.
        try? requestHandler.perform([facePoseRequest, segmentationRequest],
                                    on: framePixelBuffer,
                                    orientation: .right)

        // Get the pixel buffer that contains the mask image.
        guard let maskPixelBuffer =
                segmentationRequest.results?.first?.pixelBuffer else { return }

        // Process the images.
        self.blend(original: framePixelBuffer, mask: maskPixelBuffer)
    }

    // MARK: - Process Results

    // Performs the blend operation.
    private func blend(original framePixelBuffer: CVPixelBuffer,
                       mask maskPixelBuffer: CVPixelBuffer) {

        // Remove the optionality from generated color intensities or exit early.
        guard let colors = colors else { return }

        // Create CIImage objects for the video frame and the segmentation mask.
        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Scale the mask image to fit the bounds of the video frame.
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        // Define RGB vectors for CIColorMatrix filter.
        let vectors = [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: colors.red),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: colors.green),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: colors.blue)
        ]

        // Create a colored background image.
        let backgroundImage = maskImage.applyingFilter("CIColorMatrix",
                                                       parameters: vectors)

        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = backgroundImage
        blendFilter.maskImage = maskImage

        // Set the new, blended image as current.
        self.currentCIImage = blendFilter.outputImage?.oriented(.left)
    }
}

/// A structure that provides an RGB color intensity value for the roll, pitch, and yaw angles.
struct AngleColors {

    let red: CGFloat
    let blue: CGFloat
    let green: CGFloat

    init(roll: NSNumber?, pitch: NSNumber?, yaw: NSNumber?) {
        red = AngleColors.convert(value: roll, with: -.pi, and: .pi)
        blue = AngleColors.convert(value: pitch, with: -.pi / 2, and: .pi / 2)
        green = AngleColors.convert(value: yaw, with: -.pi / 2, and: .pi / 2)
    }

    static func convert(value: NSNumber?, with minValue: CGFloat, and maxValue: CGFloat) -> CGFloat {
        guard let value = value else { return 0 }
        let maxValue = maxValue * 0.8
        let minValue = minValue + (maxValue * 0.2)
        let facePoseRange = maxValue - minValue

        guard facePoseRange != 0 else { return 0 } // protect from zero division

        let colorRange: CGFloat = 1
        return (((CGFloat(truncating: value) - minValue) * colorRange) / facePoseRange)
    }
}
