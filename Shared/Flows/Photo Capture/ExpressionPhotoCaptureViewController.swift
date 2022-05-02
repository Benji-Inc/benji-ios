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
    private let label = ThemeLabel(font: .medium)

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        
        self.faceCaptureVC.faceCaptureSession.flashMode = .off

        self.view.addSubview(self.tapView)
        
        self.view.addSubview(self.label)

        self.tapView.didSelect { [unowned self] in
            if self.faceCaptureVC.isSessionRunning {
                self.faceCaptureVC.capturePhoto()
            } else {
                self.faceCaptureVC.view.isVisible = true
                self.faceCaptureVC.beginSession()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.animate(text: "Tap to take picture")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.faceCaptureVC.isSessionRunning {
            self.faceCaptureVC.beginSession()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()
        self.faceCaptureVC.cameraViewContainer.makeRound()

        self.tapView.expandToSuperviewSize()
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.centerOnXAndY()
    }
    
    private var animateTask: Task<Void, Never>?
    
    func animate(text: String) {
        
        self.animateTask?.cancel()
        
        self.animateTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.label.alpha = 0
            })
            
            guard !Task.isCancelled else { return }
            
            self.label.setText(text)
            self.view.layoutNow()
            
            await UIView.awaitAnimation(with: .fast, animations: {
                self.label.alpha = 1.0
            })
        }
    }
}
