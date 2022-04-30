//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionPhotoCaptureViewController: ViewController {

    var onDidComplete: ((Result<Data?, Error>) -> Void)?

    // MARK: - Views

    lazy var faceCaptureVC = FaceImageCaptureViewController()
    /// Tapping on this view will trigger the photo capture.
    private var tapView = BaseView()
    private let label = ThemeLabel(font: .medium)
    let personGradientView = PersonGradientView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        self.faceCaptureVC.faceBoxView.alpha = 0
        
        self.faceCaptureVC.view.layer.borderColor = ThemeColor.B1.color.cgColor
        self.faceCaptureVC.view.layer.borderWidth = 2
        self.faceCaptureVC.view.clipsToBounds = true 

        self.view.addSubview(self.tapView)
        
        self.view.addSubview(self.label)
        
        self.view.addSubview(self.personGradientView)
        self.personGradientView.isVisible = false

        self.tapView.didSelect { [unowned self] in
            if self.faceCaptureVC.isSessionRunning {
                self.faceCaptureVC.capturePhoto()
            } else {
                self.faceCaptureVC.view.isVisible = true
                self.personGradientView.isVisible = false 
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
        
        self.faceCaptureVC.view.squaredSize = self.view.height * 0.4
        self.faceCaptureVC.view.pinToSafeArea(.top, offset: .custom(20))
        self.faceCaptureVC.view.centerOnX()
        self.faceCaptureVC.view.makeRound()

        self.tapView.expandToSuperviewSize()
        
        self.personGradientView.frame = self.faceCaptureVC.view.frame
        
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
