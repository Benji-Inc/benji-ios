//
//  MomentVideoCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class MomentVideoCaptureViewController: VideoCaptureViewController {

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()
        
        self.captureSession.flashMode = .off
    }
    
    func beginVideoCapture() {
        if self.isSessionRunning {
            self.startVideoCapture()
        } else {
            self.view.isVisible = true
            self.beginSession()
        }
    }
    
    func endVideoCapture() {
        switch self.videoCaptureState {
        case .starting, .started, .capturing:
            self.finishVideoCapture()
        case .idle, .ending:
            break
        }
    }
}
