//
//  PiPRecorder.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

struct PiPRecording {
    var frontRecordingURL: URL?
    var backRecordingURL: URL?
}

class PiPRecorder {
    
    private var frontAssetWriter: AVAssetWriter?
    private var frontAssetWriterVideoInput: AVAssetWriterInput?
    
    private var backAssetWriter: AVAssetWriter?
    private var backAssetWriterVideoInput: AVAssetWriterInput?
    
    private let frontVideoSettings: [String: Any]
    private let backVideoSettings: [String: Any]
    
    init(frontVideoSettings: [String: Any], backVideoSettings: [String: Any]) {
        self.frontVideoSettings = frontVideoSettings
        self.backVideoSettings = backVideoSettings
        self.prepareToRecord()
    }
    
    private func prepareToRecord() {
        self.initializeFront()
        self.initializeBack()
    }
    
    private func initializeFront() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.frontVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterVideoInput)
        
        self.frontAssetWriter = assetWriter
        self.frontAssetWriterVideoInput = assetWriterVideoInput
    }
    
    private func initializeBack() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.backVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterVideoInput)
        
        self.backAssetWriter = assetWriter
        self.backAssetWriterVideoInput = assetWriterVideoInput
    }
    
    func startRecording(frontSampleBuffer: CMSampleBuffer, backSampleBuffer: CMSampleBuffer) {
        guard let frontWriter = self.frontAssetWriter, let backWriter = self.backAssetWriter else { return }
        
        // Front
        if frontWriter.status == .unknown {
            frontWriter.startWriting()
            frontWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(frontSampleBuffer))
        } else if frontWriter.status == .writing {
            if let input = self.frontAssetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(frontSampleBuffer)
            }
        }
        
        // Back
        if backWriter.status == .unknown {
            backWriter.startWriting()
            backWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(frontSampleBuffer))
        } else if backWriter.status == .writing {
            if let input = self.backAssetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(frontSampleBuffer)
            }
        }
    }
    
    func stopRecording() async -> PiPRecording? {
        
        let frontURL = await self.stopRecordingFront()
        let backURL = await self.stopRecordingBack()
        
        return PiPRecording(frontRecordingURL: frontURL,
                            backRecordingURL: backURL)
    }
    
    private func stopRecordingFront() async -> URL? {
        return await withCheckedContinuation({ continuation in
            if let assetWriter = self.frontAssetWriter {
                self.frontAssetWriter = nil
                
                assetWriter.finishWriting {
                    continuation.resume(returning: assetWriter.outputURL)
                }
            } else {
                continuation.resume(returning: nil)
            }
        })
    }
    
    private func stopRecordingBack() async -> URL? {
        return await withCheckedContinuation({ continuation in
            if let assetWriter = self.frontAssetWriter {
                self.frontAssetWriter = nil
                
                assetWriter.finishWriting {
                    continuation.resume(returning: assetWriter.outputURL)
                }
            } else {
                continuation.resume(returning: nil)
            }
        })
    }
}
