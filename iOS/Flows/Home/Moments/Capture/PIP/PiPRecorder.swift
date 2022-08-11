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
    var previewURL: URL?
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
    
    private var backVideoSettings: [String: Any]?
    
    let pixelBufferAttributes: [String: Any] = [ kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                                                           kCVPixelBufferWidthKey: 480,
                                                          kCVPixelBufferHeightKey: 480,
                                              kCVPixelBufferMetalCompatibilityKey: true] as [String: Any]
    
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
        
    var didCapturePIPRecording: ((PiPRecording) -> Void)?
    
    func initialize(backVideoSettings: [String: Any]?) {
        FileManager.clearTmpDirectory()
        self.finishVideoTask = nil 
        self.backVideoSettings = backVideoSettings
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
    }
    
    private func initializeBack() {
        // Create an asset writer that records to a temporary file
        let outputFileName = NSUUID().uuidString + "back"
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov), let settings = self.backVideoSettings else {
            return
        }
                
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        self.backAssetWriter = assetWriter
        self.backAssetWriterVideoInput = assetWriterVideoInput
    }
    
    func startFrontSession(with sampleBuffer: CMSampleBuffer) {
        guard let writer = self.frontAssetWriter else { return }
        writer.startWriting()
        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        writer.startSession(atSourceTime: startTime)
    }
    
    func startBackSession(with sampleBuffer: CMSampleBuffer) {
        guard let writer = self.backAssetWriter else { return }
        writer.startWriting()
        let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        writer.startSession(atSourceTime: startTime)
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
        return true
    }
    
    @discardableResult
    func writeBackSampleToFile(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let input = self.backAssetWriterVideoInput, input.isReadyForMoreMediaData else {
            return false
        }
        input.append(sampleBuffer)
        return true
    }
    
    private var finishVideoTask: Task<Void, Error>?

    // This cant be called more than once per recording otherwise inputs will crash
    func finishWritingVideo() async throws {
        // If we already have an initialization task, wait for it to finish.
        if let finishVideoTask = self.finishVideoTask {
            try await finishVideoTask.value
            return
        }

        // Otherwise start a new initialization task and wait for it to finish.
        self.finishVideoTask = Task {
            let frontURL = await self.stopRecordingFront()
            let backURL = await self.stopRecordingBack()
            let previewURL = await self.compressVideo(for: backURL)
            let recording = PiPRecording(frontRecordingURL: frontURL,
                                         backRecordingURL: backURL,
                                         previewURL: previewURL)
            self.didCapturePIPRecording?(recording)
        }

        do {
            try await self.finishVideoTask?.value
        } catch {
            // Dispose of the task because it failed, then pass the error along.
            self.finishVideoTask = nil
            throw error
        }
    }
    
    private func stopRecordingFront() async -> URL? {
        guard let writer = self.frontAssetWriter else { return nil }

        if writer.status == .writing {
            self.frontAssetWriterVideoInput?.markAsFinished()
            await writer.finishWriting()
            return writer.outputURL
        } else {
            logDebug("Front Failied \(writer.status)")
            return nil
        }
    }
    
    private func stopRecordingBack() async -> URL? {
        guard let writer = self.backAssetWriter else { return nil }

        if writer.status == .writing {
            self.backAssetWriterVideoInput?.markAsFinished()
            await writer.finishWriting()
            return writer.outputURL
        } else {
            logDebug("Back Failied \(writer.status)")
            return nil
        }
    }
    
    private func compressVideo(for inputURL: URL?) async -> URL? {
        guard let inputURL = inputURL else {
            return nil 
        }

        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        
        let outputFileName = NSUUID().uuidString + "preview"
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
        
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetLowQuality) else {
            return nil
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        await exportSession.export()
        return outputURL
    }
}
