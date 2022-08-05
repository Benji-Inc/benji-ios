//
//  VideoPreviewView.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import AVFoundation

class VideoPreviewView: BaseView {
    
    let playbackView = VideoView()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        return layer
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func initializeSubviews() {
        super.initializeSubviews()
        
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.addSubview(self.playbackView)
        self.playbackView.alpha = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.playbackView.expandToSuperviewSize()
    }
    
    func beginPlayback(with url: URL) {
        self.playbackView.videoURL = url
        self.playbackView.alpha = 1.0
        self.videoPreviewLayer.opacity = 0.0
    }
    
    func stopPlayback() {
        self.playbackView.videoURL = nil
        self.playbackView.alpha = 0.0
        self.videoPreviewLayer.opacity = 1.0 
    }
}
