//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionPhotoCaptureViewController: ViewController {

    // MARK: - Views

    lazy var faceCaptureVC = FaceImageCaptureViewController()
    /// Tapping on this view will trigger the photo capture.
    private var tapView = BaseView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        
        self.faceCaptureVC.faceCaptureSession.flashMode = .off

        self.view.addSubview(self.tapView)
        
        self.tapView.didSelect { [unowned self] in
            if self.faceCaptureVC.isSessionRunning {
//                self.faceCaptureVC.capturePhoto()

                self.faceCaptureVC.startVideoCapture()
                delay(2) {
                    self.faceCaptureVC.finishVideoCapture()
                }
            } else {
                self.faceCaptureVC.view.isVisible = true
                self.faceCaptureVC.beginSession()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceCaptureVC.animate(text: "Tap to take picture")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()
        self.faceCaptureVC.cameraViewContainer.makeRound()

        self.tapView.expandToSuperviewSize()
    }
}
