//
//  PiPRecorder.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/3/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

struct PiPRecording {
    var frontRecordingURL: URL?
    var backRecordingURL: URL?
}

class PiPRecorder {
    
    private var frontAssetWriter: AVAssetWriter?
    private var frontAssetWriterVideoInput: AVAssetWriterInput?
    
    private var backAssetWriter: AVAssetWriter?
    private var backAssetWriterVideoInput: AVAssetWriterInput?
    
    private let frontVideoSettings: [String: Any] = [AVVideoCodecKey : AVVideoCodecType.hevcWithAlpha,
                                                     AVVideoWidthKey : 480,
                                                    AVVideoHeightKey : 480,
                                     AVVideoCompressionPropertiesKey : [AVVideoQualityKey : 0.5,
                                          kVTCompressionPropertyKey_TargetQualityForAlpha : 0.5]]
    
    let pixelBufferAttributes: [String: Any] = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                                                           kCVPixelBufferWidthKey: 480,
                                                          kCVPixelBufferHeightKey: 480,
                                              kCVPixelBufferMetalCompatibilityKey: true] as [String: Any]
    
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private let backVideoSettings: [String: Any] = [:]
    
    private(set) var recording: PiPRecording?
    var didCapturePIPRecording: CompletionOptional = nil
    
    init() {
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
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov), !self.frontVideoSettings.isEmpty else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.frontVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
        assetWriter.add(assetWriterVideoInput)
        
        self.frontAssetWriter = assetWriter
        self.frontAssetWriterVideoInput = assetWriterVideoInput
        
        self.pixelBufferAdaptor
        = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                               sourcePixelBufferAttributes: self.pixelBufferAttributes)

    }
    
    private func initializeBack() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov), !self.backVideoSettings.isEmpty else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.backVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterVideoInput)
        
        self.backAssetWriter = assetWriter
        self.backAssetWriterVideoInput = assetWriterVideoInput
    }
    
    func startRecordingFront(with sampleBuffer: CMSampleBuffer, image: CIImage) {
        guard let input = self.frontAssetWriterVideoInput, input.isReadyForMoreMediaData else { return }

        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey : kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey : kCFBooleanTrue] as CFDictionary
        let width = Int(image.extent.width)
        let height = Int(image.extent.width)

        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)

        let context = CIContext()
        // Using a magic number (-240) for now. We should figure out the appropriate offset dynamically.
        let transform = CGAffineTransform(translationX: 0, y: -240)
        let adjustedImage = image.transformed(by: transform)
        context.render(adjustedImage, to: pixelBuffer!)

        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let presentationTime = CMTime(seconds: currentTime,
                                      preferredTimescale: CMTimeScale(bitPattern: 600))

        self.pixelBufferAdaptor?.append(pixelBuffer!, withPresentationTime: presentationTime)
    }
    
    func startRecordingBack(with sampleBuffer: CMSampleBuffer) {
        self.recording = nil
        
        guard let backWriter = self.backAssetWriter else { return }

        
        // Back
        if backWriter.status == .unknown {
            backWriter.startWriting()
            backWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if backWriter.status == .writing {
            if let input = self.backAssetWriterVideoInput,
               input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    func stopRecording() {
        Task {
            let frontURL = await self.stopRecordingFront()
            let backURL = await self.stopRecordingBack()
            
            let recording = PiPRecording(frontRecordingURL: frontURL,
                                         backRecordingURL: backURL)
            self.recording = recording
            self.didCapturePIPRecording?()
        }
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
