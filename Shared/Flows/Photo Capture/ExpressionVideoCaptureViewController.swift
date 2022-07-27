//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionVideoCaptureViewController: FaceCaptureViewController {

    // MARK: - Views

    private let emotionGradientView = EmotionGradientView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.emotionGradientView, at: 0)
        self.emotionGradientView.alpha = 0.75
        
        self.captureSession.flashMode = .off
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.animate(text: "Press and Hold")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.emotionGradientView.frame = self.cameraViewContainer.frame
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
    
    func set(favoriteType: FavoriteType) {
        self.emotionGradientView.set(emotionCounts: [favoriteType.emotion: 1])
        self.view.setNeedsLayout()
    }
}
