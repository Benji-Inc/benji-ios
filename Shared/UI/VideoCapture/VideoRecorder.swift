//
//  VideoRecorder.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

class VideoRecorder {
    
    private var assetWriter: AVAssetWriter?
    
    private(set) var assetWriterVideoInput: AVAssetWriterInput?
    
    private(set) var assetWriterAudioInput: AVAssetWriterInput?
    
    private var videoTransform: CGAffineTransform?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var videoSettings: [String: Any]
    private var audioSettings: [String: Any]?
    private var pixelBufferAttributes: [String: Any]?

    private(set) var isReadyToRecord = false
    
    init(audioSettings: [String: Any]?,
         videoSettings: [String: Any],
         pixelBufferAttributes: [String: Any],
         videoTransform: CGAffineTransform?) {
        
        self.audioSettings = audioSettings
        self.videoSettings = videoSettings
        self.videoTransform = videoTransform
        self.pixelBufferAttributes = pixelBufferAttributes
        
        self.prepareToRecord()
    }
    
    func prepareToRecord() {
        // Create an asset writer that records to a temporary file
        let uuid = UUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory(),
                      isDirectory: true).appendingPathComponent(uuid+".mov")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        
        // Add an audio input
        if let settings = self.audioSettings {
            let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
            assetWriterAudioInput.expectsMediaDataInRealTime = true
            assetWriter.add(assetWriterAudioInput)
            self.assetWriterAudioInput = assetWriterAudioInput
        }
        
        // Add a video input
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: self.videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if let transform = self.videoTransform {
            assetWriterVideoInput.transform = transform
        }
        assetWriter.add(assetWriterVideoInput)
        
        self.pixelBufferAdaptor
        = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput,
                                               sourcePixelBufferAttributes: self.pixelBufferAttributes)
        
        self.assetWriter = assetWriter
        self.assetWriterVideoInput = assetWriterVideoInput
        
        self.isReadyToRecord = true
    }
    
    func stopRecording() async -> URL? {
        return await withCheckedContinuation({ continuation in
            if let assetWriter = self.assetWriter {
                self.isReadyToRecord = false
                self.assetWriter = nil
                
                assetWriter.finishWriting {
                    continuation.resume(returning: assetWriter.outputURL)
                }
            } else {
                continuation.resume(returning: nil)
            }
        })
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard self.isReadyToRecord, let assetWriter = self.assetWriter else {
                return
        }
        
        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if assetWriter.status == .writing {
            if let input = assetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard self.isReadyToRecord,
              let assetWriter = self.assetWriter,
              assetWriter.status == .writing,
              let input = self.assetWriterAudioInput,
              input.isReadyForMoreMediaData else {
                return
        }
        
        input.append(sampleBuffer)
    }
}
