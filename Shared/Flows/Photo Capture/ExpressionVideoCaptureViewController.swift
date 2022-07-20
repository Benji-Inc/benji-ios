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

    private let emotionGradientView = EmotionGradientView()
    lazy var faceCaptureVC = FaceCaptureViewController()
    private let label = ThemeLabel(font: .emoji)

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.emotionGradientView)
        self.emotionGradientView.alpha = 0.75

        self.addChild(viewController: self.faceCaptureVC)
        
        self.view.addSubview(self.label)
        self.label.isVisible = false 
        self.label.textAlignment = .center
        
        self.faceCaptureVC.faceCaptureSession.flashMode = .off
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceCaptureVC.animate(text: "Press and Hold")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()
        self.emotionGradientView.frame = self.faceCaptureVC.cameraViewContainer.frame
        
        let offset = self.emotionGradientView.height * 0.1
        self.label.sizeToFit()
        self.label.match(.right, to: .right, of: self.emotionGradientView, offset: .custom(-offset))
        self.label.match(.bottom, to: .bottom, of: self.emotionGradientView, offset: .custom(-offset))
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
    
    func set(favoriteType: FavoriteType) {
        self.emotionGradientView.set(emotionCounts: [favoriteType.emotion: 1])
        self.label.isVisible = true
        self.label.setText(favoriteType.emoji)
        self.view.setNeedsLayout()
    }
}
