//
//  LoginProfilePhotoViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/12/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROLocalization
import Lottie
import UIKit
import Combine

enum PhotoState {
    case initial
    case scan
    case capture
    case error
    case finish
}

class PhotoViewController: ViewController, Sizeable, Completable {
    typealias ResultType = Void

    var onDidComplete: ((Result<Void, Error>) -> Void)?

    private lazy var cameraVC: FaceDetectionViewController = {
        let vc: FaceDetectionViewController = UIStoryboard(name: "FaceDetection", bundle: nil).instantiateViewController(withIdentifier: "FaceDetection") as! FaceDetectionViewController

        return vc
    }()

    private let animationView = AnimationView(name: "face_scan")
    private let avatarView = AvatarView()

    private let beginButton = Button()
    private let confirmButton = Button()
    private let retakeButton = Button()

    private let buttonContainer = View()
    private var buttonContainerRect: CGRect?

    private var image: UIImage?

    @Published private(set) var currentState: PhotoState = .initial

    override func initializeViews() {
        super.initializeViews()

        self.animationView.loopMode = .loop

        self.view.addSubview(self.animationView)
        self.animationView.alpha = 0
        self.view.addSubview(self.avatarView)
        self.addChild(viewController: self.cameraVC)

        self.hideAvatar(with: 0)
        self.view.addSubview(self.buttonContainer)

        self.cameraVC.view.clipsToBounds = true 
        self.cameraVC.view.layer.cornerRadius = 5
        self.cameraVC.view.layer.borderColor = Color.background2.color.cgColor
        self.cameraVC.view.layer.borderWidth = 2
        self.cameraVC.view.alpha = 1
        self.cameraVC.didCapturePhoto = { [unowned self] image in
            self.update(image: image)
        }

        self.$currentState
            .mainSink { [weak self] (state) in
                guard let `self` = self else { return }
                self.handle(state: state)
            }.store(in: &self.cancellables)

        self.cameraVC.$faceDetected
            .mainSink(receiveValue: { [unowned self] (faceDetected) in
                self.beginButton.isEnabled = faceDetected

                guard self.currentState == .scan else { return }
                if faceDetected {
                    self.beginButton.set(style: .normal(color: .lightPurple, text: "Capture"))
                } else {
                    self.beginButton.set(style: .normal(color: .red, text: "NO face detected"))
                }
            }).store(in: &self.cancellables)

        self.beginButton.didSelect { [unowned self] in
            if self.currentState == .initial {
                self.currentState = .scan
            } else if self.currentState == .scan {
                self.currentState = .capture
            }
        }

        self.retakeButton.set(style: .normal(color: .red, text: "Retake"))
        self.retakeButton.didSelect { [unowned self] in
            self.currentState = .scan
        }

        self.confirmButton.set(style: .normal(color: .purple, text: "Continue"))
        self.confirmButton.didSelect { [unowned self] in
            guard let fixed = self.image else { return }
            self.saveProfilePicture(image: fixed)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.currentState = .initial
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.animationView.size = CGSize(width: 140, height: 140)
        self.animationView.centerY = self.view.halfHeight * 0.8
        self.animationView.centerOnX()

        let cameraHeight = self.view.height * 0.7
        self.cameraVC.view.size = CGSize(width: cameraHeight * 0.74, height: cameraHeight)
        self.cameraVC.view.centerOnX()
        self.cameraVC.view.top = 30

        self.avatarView.frame = self.cameraVC.view.frame

        let rect = self.buttonContainerRect ?? CGRect(x: Theme.contentOffset,
                                                      y: self.view.bottom,
                                                      width: self.view.width - (Theme.contentOffset * 2),
                                                      height: Theme.buttonHeight)

        self.buttonContainer.frame = rect
    }

    private func handle(state: PhotoState) {
        switch state {
        case .initial:
            delay(0.5) {
                self.handleInitialState()
            }
        case .scan:
            self.handleScanState()
        case .capture:
            self.handleCaptureState()
        case .error:
            self.handleErrorState()
        case .finish:
            self.handleFinishState()
        }

        self.view.layoutNow()
    }

    private func handleInitialState() {
        self.beginButton.isEnabled = true
        self.beginButton.set(style: .normal(color: .green, text: "Begin"))

        if self.animationView.alpha == 0 {
            UIView.animate(withDuration: Theme.animationDuration, animations: {
                self.animationView.alpha = 1
            }) { (completed) in
                self.animationView.play()
            }
        } else {
            delay(Theme.animationDuration) {
                self.animationView.play()
            }
        }

        self.buttonContainer.removeAllSubviews()
        self.buttonContainer.addSubview(self.beginButton)
        self.beginButton.expandToSuperviewSize()
        self.showButtons()
    }

    private func handleScanState() {
        self.hideAvatar()
        self.beginButton.isEnabled = true

        self.hideButtons { [unowned self] in
            //Hide animation view
            UIView.animate(withDuration: 0.2, animations: {
                self.animationView.alpha = 0
                self.beginButton.set(style: .normal(color: .lightPurple, text: "Capture"))
            }) { (completed) in
                // Begin capture
                self.cameraVC.begin()
            }

            self.buttonContainer.addSubview(self.beginButton)
            self.beginButton.expandToSuperviewSize()
            self.showButtons()
        }
    }

    private func handleCaptureState() {
        self.cameraVC.capturePhoto()

        //Hide button container
        self.hideButtons { [unowned self] in
            //Add buttons
            self.buttonContainer.addSubview(self.retakeButton)
            let size = CGSize(width: self.buttonContainer.halfWidth - Theme.contentOffset,
                              height: self.buttonContainer.height)
            self.retakeButton.size = size
            self.retakeButton.left = 0
            self.retakeButton.top = 0

            self.buttonContainer.addSubview(self.confirmButton)
            self.confirmButton.size = size
            self.confirmButton.right = self.buttonContainer.width
            self.confirmButton.top = 0

            //Show buttons
            self.showButtons()
        }
    }

    private func handleErrorState() {
        self.complete(with: .failure(ClientError.message(detail: "There was a problem. Please try again.")))
    }

    private func handleFinishState() {
        self.complete(with: .success(()))
        self.confirmButton.handleEvent(status: .loading)
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    private func showButtons() {
        UIView.animate(withDuration: Theme.animationDuration) {
            self.buttonContainerRect = CGRect(x: Theme.contentOffset,
                                              y: self.view.height - self.view.safeAreaInsets.bottom - Theme.buttonHeight,
                                              width: self.view.width - (Theme.contentOffset * 2),
                                              height: Theme.buttonHeight)
            self.view.layoutNow()
        }
    }

    private func hideButtons(completion: CompletionOptional = nil) {
        UIView.animate(withDuration: Theme.animationDuration, animations: {
            self.buttonContainerRect = CGRect(x: Theme.contentOffset,
                                              y: self.view.height - self.view.safeAreaInsets.bottom,
                                              width: self.view.width - (Theme.contentOffset * 2),
                                              height: Theme.buttonHeight)
            self.view.layoutNow()
        }) { (completed) in
            guard completed else { return }
            self.buttonContainer.removeAllSubviews()
            completion?()
        }
    }

    func showAvatar() {
        UIView.animate(withDuration: Theme.animationDuration,
                       animations: {
                        self.avatarView.transform = .identity
                        self.avatarView.alpha = 1
                        self.cameraVC.view.alpha = 0
                        self.view.setNeedsLayout()
                       }) { (completed) in }
    }

    func hideAvatar(with duration: TimeInterval = Theme.animationDuration) {
        UIView.animate(withDuration: duration,
                       animations: {
                        self.avatarView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                        self.avatarView.alpha = 0
                        self.cameraVC.view.alpha = 1
                        self.view.setNeedsLayout()
                       }) { (completed) in }
    }

    private func update(image: UIImage) {
        self.cameraVC.stop()

        self.avatarView.set(avatar: image)
        self.image = image

        self.showAvatar()
    }

    func saveProfilePicture(image: UIImage) {
        guard let current = User.current() else { return }

        // NOTE: Remember, we're in points not pixels. Max image size will
        // depend on image pixel density. It's okay for now.
        let maxAllowedDimension: CGFloat = 100.0
        let longSide = max(image.size.width, image.size.height)

        var scaledImage: UIImage
        if longSide > maxAllowedDimension {
            let scaleFactor: CGFloat = maxAllowedDimension / longSide
            scaledImage = image.scaled(by: scaleFactor)
        } else {
            scaledImage = image
        }

        if let scaledData = scaledImage.pngData() {
            let scaledImageFile = PFFileObject(name:"small_image.png", data: scaledData)
            current.smallImage = scaledImageFile
        }

        self.confirmButton.handleEvent(status: .loading)
        current.saveToServer()
            .flatMap({ (user) -> AnyPublisher<Any, Error> in
                return ActivateUser().makeRequest(andUpdate: [], viewsToIgnore: [self.view])
            }).mainSink(receivedResult: { (result) in
                switch result {
                case .success(_):
                    self.currentState = .finish
                case .error(_):
                    self.currentState = .error
                }
            }).store(in: &self.cancellables)
    }

    func getHeight(for width: CGFloat) -> CGFloat {
        return 450
    }
}
