//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionVideoCaptureViewController: ViewController {

    // MARK: - Views

    lazy var faceCaptureVC = FaceCaptureViewController()
    let videoPreviewView = VideoView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        
        self.faceCaptureVC.faceCaptureSession.flashMode = .off
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceCaptureVC.animate(text: "Press and Hold")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()
    }
    
    func beginVideoCapture() {
        if self.faceCaptureVC.isSessionRunning {
            self.faceCaptureVC.startVideoCapture()
        } else {
            self.faceCaptureVC.view.isVisible = true
            self.faceCaptureVC.beginSession()
        }
    }
    
    func endVideoCapture() {
        switch self.faceCaptureVC.videoCaptureState {
        case .starting, .started, .capturing:
            self.faceCaptureVC.finishVideoCapture()
        case .idle, .ending:
            break
        }
    }
}
