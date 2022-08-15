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
import Combine

extension PiPRecordingViewController {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        let isVideoOutput = output is AVCaptureVideoDataOutput
        let isFrontOutput = connection.isVideoMirrored
        
        // If mirrored, then its the front camera output
        if isFrontOutput, isVideoOutput {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            do {
                try self.sequenceHandler.perform([self.segmentationRequest],
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
        case .idle, .error:
            // Do nothing
            break
        case .initialize:
            // Initialize the AVAsset writer to prepare for capture
            let settings = self.backOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
            let audioSettings = self.micDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mp4)
            self.recorder.initialize(backVideoSettings: settings, audioSettings: audioSettings)
            self.state = .started
        case .started:
            
            if isVideoOutput {
                if isFrontOutput {
                    if !self.frontIsSampling {
                        self.recorder.startFrontSession(with: sampleBuffer)
                    }
                    self.frontIsSampling = self.recorder.writeFrontSampleToFile(sampleBuffer, image: self.frontCameraView.currentCIImage)
                } else {
                    if !self.backIsSampling {
                        self.recorder.startBackSession(with: sampleBuffer)
                    }
                    self.backIsSampling = self.recorder.writeBackSampleToFile(sampleBuffer)
                }
            } else if !self.micIsSampling, self.frontIsSampling {
                self.micIsSampling = self.recorder.recordAudio(sampleBuffer: sampleBuffer)
            }
            
            if self.frontIsSampling, self.backIsSampling, self.micIsSampling {
                self.state = .capturing
            }
        case .capturing:
            if isVideoOutput {
                if isFrontOutput {
                    self.recorder.writeFrontSampleToFile(sampleBuffer, image: self.frontCameraView.currentCIImage)
                } else {
                    self.recorder.writeBackSampleToFile(sampleBuffer)
                }
            } else {
                self.recorder.recordAudio(sampleBuffer: sampleBuffer)
            }
            
        case .ending:
            Task {
                do {
                    try await self.recorder.finishRecording()
                    self.backIsSampling = false
                    self.frontIsSampling = false
                } catch {
                    logError(error)
                }
            }
        case .playback:
            break
        }
    }
    
    /// Makes the image black and white, and makes the background clear.
    private func blend(original framePixelBuffer: CVPixelBuffer, mask maskPixelBuffer: CVPixelBuffer) -> CIImage? {
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

        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = solidColor
        blendFilter.maskImage = maskImage

        return blendFilter.outputImage?.oriented(.leftMirrored)
    }
}
