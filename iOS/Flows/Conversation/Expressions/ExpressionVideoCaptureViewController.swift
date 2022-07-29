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

    let favoriteLabel = FavoriteLabel()
    private let emotionGradientView = EmotionGradientView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.view.insertSubview(self.emotionGradientView, at: 0)
        self.emotionGradientView.alpha = 0.75
        
        self.captureSession.flashMode = .off
        self.view.addSubview(self.favoriteLabel)
        
        self.$videoCaptureState
            .removeDuplicates()
            .mainSink { [unowned self] state in
                
            UIView.animate(withDuration: Theme.animationDurationFast) {
                if state == .starting {
                    if self.favoriteLabel.transform == .identity {
                        var transform = CGAffineTransform.identity
                        transform = transform.scaledBy(x: 1.5, y: 1.5)
                        self.favoriteLabel.transform = transform
                        self.view.layoutNow()
                    }
                } else if state == .ending {
                    self.favoriteLabel.transform = .identity
                    self.view.layoutNow()
                }
            }
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.animate(text: "Press and Hold")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.cameraViewContainer.expandToSuperviewSize()
        self.cameraViewContainer.layer.cornerRadius = self.cameraViewContainer.height * 0.25
        
        self.animationView.squaredSize = self.cameraViewContainer.height * 0.5
        self.animationView.centerOnXAndY()
        
        self.cameraView.width = self.cameraViewContainer.width
        self.cameraView.height = self.cameraViewContainer.height * 1.25
        self.cameraView.pin(.top)
        self.cameraView.centerOnX()
        
        self.emotionGradientView.frame = self.cameraViewContainer.frame
        
        if self.videoCaptureState == .starting {
            self.favoriteLabel.match(.top, to: .top, of: self.label)
        } else {
            self.favoriteLabel.match(.top, to: .bottom, of: self.label, offset: .short)
        }
        
        self.favoriteLabel.centerOnX()
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
        self.favoriteLabel.configure(with: favoriteType)
        self.view.setNeedsLayout()
    }
}
