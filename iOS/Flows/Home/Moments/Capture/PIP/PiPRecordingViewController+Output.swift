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
        let isFrontVideoOutput = connection.isVideoMirrored
        
        // If mirrored, then its the front camera output
        if isFrontVideoOutput, isVideoOutput {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            do {
                try self.sequenceHandler.perform([self.segmentationRequest],
                                                 on: imageBuffer,
                                                 orientation: .left)

                // Get the pixel buffer that contains the mask image.
                guard let maskPixelBuffer
                        = self.segmentationRequest.results?.first?.pixelBuffer else { return }
                self.frontCameraView.setImage(original: imageBuffer, mask: maskPixelBuffer)
            } catch {
                logError(error)
            }
        }
        
        if self.state == .recording {
            // then record
            if isVideoOutput {
                if isFrontVideoOutput {
                    self.recorder.recordFrontVideo(sampleBuffer: sampleBuffer, ciImage: self.frontCameraView.currentCIImage)
                } else {
                    self.recorder.recordBackVideo(sampleBuffer: sampleBuffer)
                }
            } else {
                self.recorder.recordAudio(sampleBuffer: sampleBuffer)
            }
        }
    }
}
