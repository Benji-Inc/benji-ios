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
            try self.sequenceHandler.perform([detectFaceRequest,
                                              self.segmentationRequest],
                                             on: imageBuffer,
                                             orientation: self.orientation)

            // Get the pixel buffer that contains the mask image.
            guard let maskPixelBuffer
                    = self.segmentationRequest.results?.first?.pixelBuffer else { return }
            // Process the images.
            self.blend(original: imageBuffer, mask: maskPixelBuffer)

        } catch {
            logError(error)
        }
    }

    private func detectedFace(request: VNRequest, error: Error?) {
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

    // MARK: - Process Results

    // Performs the blend operation.
    func blend(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) {
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

        guard let bwImage = filter?.outputImage else { return }

        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = bwImage
        blendFilter.backgroundImage = solidColor
        blendFilter.maskImage = maskImage

        // Set the new, blended image as current.
        self.currentCIImage = blendFilter.outputImage?.oriented(.leftMirrored)
    }
}

// MARK: - MTKViewDelegate

extension FaceDetectionViewController: MTKViewDelegate {

    func draw(in view: MTKView) {
        guard let metalView = view as? MetalView else { return }

        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalView.commandQueue.makeCommandBuffer() else {
            return
        }

        // grab image
        guard let ciImage = self.currentCIImage else { return }

        // ensure drawable is free and not tied in the preivous drawing cycle
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

        // register drawwable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
    }
}
