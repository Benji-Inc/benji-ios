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

/// A view controller that allows a user to capture an image of their face.
/// A live preview of the camera is shown on the main view.
class FaceImageCaptureViewController: ViewController {

    enum VideoCaptureState {
        case idle
        case starting
        case capturing
        case ending
    }

    private(set) var videoCaptureState: VideoCaptureState = .idle

    var didCapturePhoto: ((UIImage) -> Void)?
    var didCaptureVideo: ((URL) -> Void)?

    @Published private(set) var hasRenderedFaceImage = false
    @Published private(set) var faceDetected = false
    @Published private(set) var eyesAreClosed = false
    @Published private(set) var isSmiling = false

    private var currentCIImage: CIImage? {
        didSet {
            self.cameraView.draw()
        }
    }
    
    let cameraViewContainer = UIView()

    /// Shows a live preview of the image the user could take.
    lazy var cameraView: MetalView = {
        let metalView = MetalView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.delegate = self
        metalView.alpha = 0 
        return metalView
    }()

    let orientation: CGImagePropertyOrientation = .left

    lazy var faceCaptureSession = PhotoCaptureSession()

    /// A request to separate a person from the background in an image.
    private var segmentationRequest = VNGeneratePersonSegmentationRequest()
    private var sequenceHandler = VNSequenceRequestHandler()
    
    deinit {
        if self.isSessionRunning {
            self.stopSession()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.faceCaptureSession.avCaptureDelegate = self
        
        self.view.addSubview(self.cameraViewContainer)
        self.cameraViewContainer.addSubview(self.cameraView)
        self.cameraViewContainer.layer.borderColor = ThemeColor.B1.color.cgColor
        self.cameraViewContainer.layer.borderWidth = 2
        self.cameraViewContainer.clipsToBounds = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.cameraViewContainer.squaredSize = self.view.height * 0.4
        self.cameraViewContainer.pinToSafeArea(.top, offset: .custom(20))
        self.cameraViewContainer.centerOnX()
        
        self.cameraView.width = self.cameraViewContainer.width
        self.cameraView.height = self.cameraViewContainer.height * 1.25
        self.cameraView.pin(.top)
        self.cameraView.centerOnX()
    }

    // MARK: - Photo Capture Session

    /// Returns true if the underlaying photo capture session is running.
    var isSessionRunning: Bool {
        return self.faceCaptureSession.isRunning
    }

    /// Starts the face capture session so that we can display the photo preview and capture a photo.
    func beginSession() {
        guard !self.isSessionRunning else { return }
        self.faceCaptureSession.begin()
    }
    
    /// Stops the face capture session.
    func stopSession() {
        guard self.isSessionRunning else { return }
        self.faceCaptureSession.stop()
    }

    func capturePhoto() {
        guard self.isSessionRunning else { return }

        self.captureCurrentImageAsPhoto()
    }

    private var videoWriter: AVAssetWriter!
    private var videoWriterInput: AVAssetWriterInput!
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!
    private var videoStartTime: Double!

    func startVideoCapture() {
        guard self.videoCaptureState == .idle else { return }

        self.videoCaptureState = .starting
    }

    func finishVideoCapture() {
        switch self.videoCaptureState {
        case .starting, .capturing:
            self.videoCaptureState = .ending
        case .idle, .ending:
            // Do nothing
            break
        }
    }
}

extension FaceImageCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace)

        do {
            try self.sequenceHandler.perform([detectFaceRequest, self.segmentationRequest],
                                             on: imageBuffer,
                                             orientation: self.orientation)

            // Get the pixel buffer that contains the mask image.
            guard let maskPixelBuffer
                    = self.segmentationRequest.results?.first?.pixelBuffer else { return }
            // Process the images.
            let blendedImage = self.blend(original: imageBuffer, mask: maskPixelBuffer)

            // Set the new, blended image as current.
            self.currentCIImage = blendedImage
        } catch {
            logError(error)
        }

        switch self.videoCaptureState {
        case .idle:
            // Do nothing
            break
        case .starting:
            // Initialize the AVAsset writer to prepare for capture
            self.startAssetWriter(with: sampleBuffer)
            self.videoCaptureState = .capturing
        case .capturing:
            self.writeSampleToFile(sampleBuffer)
        case .ending:
            self.finishWritingVideo()
            self.videoCaptureState = .idle
        }
    }

    private func startAssetWriter(with sampleBuffer: CMSampleBuffer) {
        do {
            // Get a url to temporarily store the video
            #warning("Use a full UUID")
            let uuid = UUID().uuidString.prefix(8)
            let url = URL(fileURLWithPath: NSTemporaryDirectory(),
                          isDirectory: true).appendingPathComponent(uuid+".mov")

            // Create an asset writer that will write the video the url
            self.videoWriter = try AVAssetWriter(outputURL: url, fileType: .mov)
            let settings: [String : Any] = [AVVideoCodecKey : AVVideoCodecType.hevc,
                                            AVVideoWidthKey : 720,
                                           AVVideoHeightKey : 720,
                            AVVideoCompressionPropertiesKey : [AVVideoQualityKey : 0.5]]

            self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video,
                                                       outputSettings: settings)
            self.videoWriterInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
            self.videoWriterInput.expectsMediaDataInRealTime = true

            self.pixelBufferAdaptor
            = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoWriterInput,
                                                   sourcePixelBufferAttributes: nil)

            if self.videoWriter.canAdd(self.videoWriterInput) {
                self.videoWriter.add(self.videoWriterInput)
            }

            self.videoWriter.startWriting()

            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.videoWriter.startSession(atSourceTime: startTime)
            self.videoStartTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        } catch {
            logError(error)
        }
    }

    private func writeSampleToFile(_ sampleBuffer: CMSampleBuffer) {
        guard self.videoWriterInput.isReadyForMoreMediaData else { return }

        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width: Int = Int(self.currentCIImage!.extent.width)
        let height: Int = Int(self.currentCIImage!.extent.width)

        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)

        let context = CIContext()
        context.render(self.currentCIImage!, to: pixelBuffer!)


        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let presentationTime = CMTime(seconds: currentTime,
                                      preferredTimescale: CMTimeScale(bitPattern: 600))

        self.pixelBufferAdaptor.append(pixelBuffer!, withPresentationTime: presentationTime)
    }

    private func finishWritingVideo() {
        self.videoWriterInput.markAsFinished()
        let videoURL = self.videoWriter.outputURL
        self.videoWriter.finishWriting {
            self.didCaptureVideo?(videoURL)
        }
    }

    private func detectedFace(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation], let _ = results.first else {
            self.faceDetected = false
            return
        }

        self.faceDetected = true
    }

    /// Makes the image black and white, and makes the background clear.
    func blend(original framePixelBuffer: CVPixelBuffer,
               mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {

        let color = CIColor(color: UIColor.clear)

        // Create CIImage objects for the video frame and the segmentation mask.
        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(self.orientation)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Scale the mask image to fit the bounds of the video frame.
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))

        let solidColor = CIImage(color: color).cropped(to: maskImage.extent)

        // List of all filters: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/

        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter?.setValue(originalImage, forKey: "inputImage")

        guard let bwImage = filter?.outputImage else { return nil }

        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = bwImage
        blendFilter.backgroundImage = solidColor
        blendFilter.maskImage = maskImage

        return blendFilter.outputImage?.oriented(.leftMirrored)
    }
}

extension FaceImageCaptureViewController: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        guard let connection = output.connection(with: .video) else { return }
        connection.automaticallyAdjustsVideoMirroring = true

        self.captureCurrentImageAsPhoto()
    }

    func captureCurrentImageAsPhoto() {
        guard let ciImage = self.currentCIImage else { return }

        // If we find a face in the image, we'll crop around it and store it here.
        var finalCIImage = ciImage

        let imageOptions = NSMutableDictionary(object: NSNumber(value: 5) as NSNumber,
                                               forKey: CIDetectorImageOrientation as NSString)
        imageOptions[CIDetectorEyeBlink] = true
        let accuracy = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: ciImage, options: imageOptions as? [String : AnyObject])

        if let face = faces?.first as? CIFaceFeature {
            self.eyesAreClosed = face.leftEyeClosed && face.rightEyeClosed
            self.isSmiling = face.hasSmile

            // Increase the bounds around the face so it's not too zoomed in.
            var adjustedFaceBounds = face.bounds
            adjustedFaceBounds.size.height = face.bounds.height * 2.2
            adjustedFaceBounds.size.width = adjustedFaceBounds.height
            adjustedFaceBounds.centerY = face.bounds.centerY + face.bounds.height * 0.2
            adjustedFaceBounds.centerX = face.bounds.centerX

            finalCIImage = ciImage.cropped(to: adjustedFaceBounds)
        } else {
            self.eyesAreClosed = false
            self.isSmiling = false
        }

        // CGImages play nicer with UIKit.
        // Per the docs: "Due to Core Image's coordinate system mismatch with UIKit, this filtering
        // approach may yield unexpected results when displayed in a UIImageView with contentMode."
        let context = CIContext()
        let cgImage = context.createCGImage(finalCIImage, from: finalCIImage.extent)!

        let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        self.didCapturePhoto?(image)
    }
}

// MARK: - MTKViewDelegate

extension FaceImageCaptureViewController: MTKViewDelegate {

    func draw(in view: MTKView) {
        guard let metalView = view as? MetalView else { return }

        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalView.commandQueue.makeCommandBuffer() else {
            return
        }

        // grab image
        guard let ciImage = self.currentCIImage else { return }

        // ensure drawable is free and not tied in the previous drawing cycle
        guard let currentDrawable = view.currentDrawable else { return }

        // make sure the image is full screen
        let drawSize = self.cameraView.drawableSize
        var scaleX = drawSize.width / ciImage.extent.width
        var scaleY = drawSize.height / ciImage.extent.height

        if scaleX > scaleY {
            scaleY = scaleX
        } else {
            scaleX = scaleY
        }

        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        //render into the metal texture
        metalView.context.render(newImage,
                                 to: currentDrawable.texture,
                                 commandBuffer: commandBuffer,
                                 bounds: newImage.extent,
                                 colorSpace: CGColorSpaceCreateDeviceRGB())

        // register drawable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        if !self.hasRenderedFaceImage {
            Task.onMainActorAsync {
                await Task.sleep(seconds: 1.5)
                self.hasRenderedFaceImage = true
                view.alpha = 1.0
            }
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
    }
}
