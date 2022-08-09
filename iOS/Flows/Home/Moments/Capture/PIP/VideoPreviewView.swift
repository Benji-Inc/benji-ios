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
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.playbackView.alpha = 1.0
        } completion: { _ in
            self.playbackView.shouldPlay = true
            self.playbackView.videoURL = url
        }
    }
    
    func stopPlayback() {
        self.playbackView.videoURL = nil
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.playbackView.alpha = 0.0
        }
    }
}
