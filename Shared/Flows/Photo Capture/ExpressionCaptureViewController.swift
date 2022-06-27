//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionCaptureViewController: ViewController {

    // MARK: - Views

    lazy var faceCaptureVC = FaceCaptureViewController()
    /// Pressing on this view will trigger the video capture
    private var pressView = BaseView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        
        self.faceCaptureVC.faceCaptureSession.flashMode = .off

        self.view.addSubview(self.pressView)

        let longPress = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(onLongPress))
        self.pressView.addGestureRecognizer(longPress)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.faceCaptureVC.animate(text: "Press and hold to take a video")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()
        self.faceCaptureVC.cameraViewContainer.makeRound()

        self.pressView.expandToSuperviewSize()
    }

    // MARK: - Input Handling

    @objc private func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            logDebug("capturing")
            if self.faceCaptureVC.isSessionRunning {
                self.faceCaptureVC.startVideoCapture()
            } else {
                self.faceCaptureVC.view.isVisible = true
                self.faceCaptureVC.beginSession()
            }
        case .ended, .cancelled:
            self.faceCaptureVC.finishVideoCapture()
        default:
            break
        }
    }
}
