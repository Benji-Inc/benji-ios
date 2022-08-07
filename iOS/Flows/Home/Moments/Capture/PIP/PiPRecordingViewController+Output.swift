//
//  PiPRecordingViewController+Output.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import Vision

extension PiPRecordingViewController {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        let isFrontOutput = connection.isVideoMirrored
        
        // If mirrored, then its the front camera output
        if isFrontOutput {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace)

            do {
                try self.sequenceHandler.perform([detectFaceRequest, self.segmentationRequest],
                                                 on: imageBuffer,
                                                 orientation: .left)

                // Get the pixel buffer that contains the mask image.
                guard let maskPixelBuffer
                        = self.segmentationRequest.results?.first?.pixelBuffer else { return }
                // Process the images.
                let blendedImage = self.blend(original: imageBuffer, mask: maskPixelBuffer)

                // Set the new, blended image as current.
                self.frontCameraView.currentCIImage = blendedImage
            } catch {
                logError(error)
            }
        }
        
        switch self.state {
        case .recording:
            if isFrontOutput {
                guard let ciImage = self.frontCameraView.currentCIImage else { return }
                self.recorder.recordFront(with: sampleBuffer, image: ciImage)
            } else {
                self.recorder.recordBack(with: sampleBuffer)
            }
        case .playback:
            self.recorder.stopRecording()
            self.state = .displaying
        default:
            break
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
    func blend(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {
        // Make the background clear.
        let color = CIColor(color: UIColor.clear)

        // Create CIImage objects for the video frame and the segmentation mask.
        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.left)
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
