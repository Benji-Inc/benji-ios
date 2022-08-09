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
    
    private let backVideoSettings: [String: Any] = [ AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey:NSNumber(value:250000)],
                                                                     AVVideoCodecKey: AVVideoCodecType.h264,
                                                                    AVVideoHeightKey: 480,
                                                                     AVVideoWidthKey: 480] as [String: Any]
    
    let pixelBufferAttributes: [String: Any] = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                                                           kCVPixelBufferWidthKey: 480,
                                                          kCVPixelBufferHeightKey: 480,
                                              kCVPixelBufferMetalCompatibilityKey: true] as [String: Any]
    
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
        
    var didCapturePIPRecording: ((PiPRecording) -> Void)?
    
    func initialize() {
        self.initializeFront()
        self.initializeBack()
    }
    
    private func initializeFront() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString + "front"
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.frontVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.mediaTimeScale = CMTimeScale(bitPattern: 600)
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        self.frontAssetWriter = assetWriter
        self.frontAssetWriterVideoInput = assetWriterVideoInput
        
        self.pixelBufferAdaptor
        = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                               sourcePixelBufferAttributes: self.pixelBufferAttributes)
        
        assetWriter.startWriting()
    }
    
    private func initializeBack() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString + "back"
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.backVideoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        self.backAssetWriter = assetWriter
        self.backAssetWriterVideoInput = assetWriterVideoInput
    }
    
    func startFrontSession(with sampleBuffer: CMSampleBuffer) {
        guard let writer = self.frontAssetWriter else { return }
        
        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        writer.startSession(atSourceTime: startTime)
        logDebug("FRONT STARTED")
    }
    
    func startBackSession(with sampleBuffer: CMSampleBuffer) {
        guard let writer = self.backAssetWriter, writer.status != .writing else { return }
        writer.startWriting()
        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        writer.startSession(atSourceTime: startTime)
        logDebug("BACK STARTED")
    }
    
    @discardableResult
    func writeFrontSampleToFile(_ sampleBuffer: CMSampleBuffer, image: CIImage?) -> Bool {
        guard let input = self.frontAssetWriterVideoInput,
                input.isReadyForMoreMediaData,
              let currentImage = image else { return false }
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey : kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey : kCFBooleanTrue] as CFDictionary
        let width = Int(currentImage.extent.width)
        let height = Int(currentImage.extent.width)

        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)

        let context = CIContext()
        // Using a magic number (-240) for now. We should figure out the appropriate offset dynamically.
        let transform = CGAffineTransform(translationX: 0, y: -240)
        let adjustedImage = currentImage.transformed(by: transform)
        context.render(adjustedImage, to: pixelBuffer!)

        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        let presentationTime = CMTime(seconds: currentTime,
                                      preferredTimescale: CMTimeScale(bitPattern: 600))

        self.pixelBufferAdaptor?.append(pixelBuffer!, withPresentationTime: presentationTime)
        //logDebug("front")
        return true
    }
    
    @discardableResult
    func writeBackSampleToFile(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let input = self.backAssetWriterVideoInput, input.isReadyForMoreMediaData else {
            return false
        }
        //logDebug("back")
        input.append(sampleBuffer)
        return true
    }
    
    func finishWritingVideo() {
        
        self.stopRecordingFront { [unowned self] url in
            let recording = PiPRecording(frontRecordingURL: url,
                                         backRecordingURL: URL(string: ""))
            self.didCapturePIPRecording?(recording)
        }
//        Task {
//            let frontURL = await self.stopRecordingFront()
//            //let backURL = await self.stopRecordingBack()
//
//            let recording = PiPRecording(frontRecordingURL: frontURL,
//                                         backRecordingURL: URL(string: ""))
//            self.didCapturePIPRecording?(recording)
//        }
    }
    
    private func stopRecordingFront(completion: @escaping ((URL?) -> Void)) {
        guard let writer = self.frontAssetWriter else { return  }

        if writer.status == .writing {
            self.frontAssetWriterVideoInput?.markAsFinished()
            writer.finishWriting {
                completion(writer.outputURL)
            }
        } else {
            logDebug("Front Failied \(writer.status)")
            completion(nil)
        }
    }
    
    private func stopRecordingBack() async -> URL? {
        guard let writer = self.backAssetWriter else { return nil }

        if writer.status == .writing {
            await writer.finishWriting()
            self.backAssetWriterVideoInput?.markAsFinished()
            return writer.outputURL
        } else {
            logDebug("Back Failied \(writer.status)")
            return nil
        }
    }
}
