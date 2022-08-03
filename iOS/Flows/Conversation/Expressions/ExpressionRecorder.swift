//
//  ExpressionRecorder.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation
import VideoToolbox

class ExpressionRecorder: VideoRecorder {
    
    init() {
        
        let settings: [String : Any] = [AVVideoCodecKey : AVVideoCodecType.hevcWithAlpha,
                                        AVVideoWidthKey : 480,
                                       AVVideoHeightKey : 480,
                        AVVideoCompressionPropertiesKey : [AVVideoQualityKey : 0.5,
                             kVTCompressionPropertyKey_TargetQualityForAlpha : 0.5]
        ]
        
        let pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: 480,
            kCVPixelBufferHeightKey: 480,
            kCVPixelBufferMetalCompatibilityKey: true] as [String: Any]
        
        super.init(audioSettings: nil,
                   videoSettings: settings,
                   pixelBufferAttributes: pixelBufferAttributes)
        
        self.assetWriterVideoInput?.mediaTimeScale = CMTimeScale(bitPattern: 600)
    }
}
