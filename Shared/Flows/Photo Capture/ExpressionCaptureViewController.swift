//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ExpressionPhotoCaptureViewController: ViewController {

    var onDidComplete: ((Result<UIImage?, Error>) -> Void)?

    // MARK: - Views

    lazy var faceCaptureVC = FaceImageCaptureViewController()
    /// Tapping on this view will trigger the photo capture.
    private var tapView = BaseView()

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.modalPresentationStyle = .overFullScreen

        self.addChild(viewController: self.faceCaptureVC)
        #warning("Improve?")
        self.faceCaptureVC.faceBoxView.alpha = 1

        self.view.addSubview(self.tapView)

        self.tapView.didSelect { [unowned self] in
            self.faceCaptureVC.capturePhoto()
        }

        self.faceCaptureVC.didCapturePhoto = { [unowned self] image in
            var finalImage = image
            if let previewData = image.previewHeicData, let previewImage = UIImage(data: previewData) {
                finalImage = previewImage
            }

            self.onDidComplete?(.success(finalImage))
        }
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
        self.tapView.expandToSuperviewSize()
    }
}
