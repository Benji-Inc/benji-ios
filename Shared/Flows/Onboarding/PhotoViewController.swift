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
import AVFoundation

enum PhotoState {
    case initial
    case scanEyesOpen
    case scanEyesClosed
    case captureEyesOpen
    case captureEyesClosed
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

    private let animationView = AnimationView.with(animation: .faceScan)
    private let button = Button()
    private let instructionLabel = Label(font: .smallBold, textColor: .background4)
    private let errorLabel = Label(font: .smallBold, textColor: .background4)
    private let gradientView = GradientView(with: [Color.background2.color.cgColor, Color.clear.color.cgColor], startPoint: .bottomCenter, endPoint: .topCenter)

    @Published private(set) var currentState: PhotoState = .initial

    override func initializeViews() {
        super.initializeViews()

        self.animationView.loopMode = .loop

        self.view.addSubview(self.animationView)
        self.animationView.alpha = 0
        self.addChild(viewController: self.cameraVC)

        self.view.addSubview(self.errorLabel)
        self.errorLabel.alpha = 0
        self.errorLabel.textAlignment = .center

        self.view.addSubview(self.gradientView)

        self.view.addSubview(self.instructionLabel)
        self.instructionLabel.alpha = 0
        self.instructionLabel.textAlignment = .center

        self.view.addSubview(self.button)
        self.button.didSelect { [unowned self] in
            switch self.currentState {
            case .initial:
                self.currentState = .scanEyesOpen
            default:
                break
            }
        }

//        self.view.onDoubleTap { [unowned self] _ in
//            guard self.currentState == .captureEyesOpen else { return }
//            self.currentState = .scan
//        }

        self.view.didSelect { [unowned self] in
            guard self.cameraVC.faceDetected else { return }

            if self.currentState == .scanEyesOpen {
                self.currentState = .captureEyesOpen
            } else if self.currentState == .scanEyesClosed {
                self.currentState = .captureEyesClosed
            }
        }

        self.cameraVC.didCapturePhoto = { [unowned self] image in
            if self.currentState == .captureEyesClosed {
                if self.cameraVC.eyesAreClosed {
                    Task {
                        await self.updateUser(with: image)
                    }
                } else {
                    self.handleEyesClosed()
                }
            } else {
                Task {
                    await self.updateUser(with: image)
                }
            }
        }

        self.$currentState
            .mainSink { [weak self] (state) in
                guard let `self` = self else { return }
                self.handle(state: state)
            }.store(in: &self.cancellables)

        self.cameraVC.$faceDetected
            .removeDuplicates()
            .mainSink(receiveValue: { [unowned self] (faceDetected) in
                guard self.currentState == .scanEyesOpen || self.currentState == .scanEyesClosed else { return }
                self.handleFace(isDetected: faceDetected)
            }).store(in: &self.cancellables)
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

        self.cameraVC.view.expandToSuperviewSize()

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()

        self.gradientView.height = self.view.height - self.button.top
        self.gradientView.expandToSuperviewWidth()
        self.gradientView.pin(.bottom)

        self.errorLabel.setSize(withWidth: self.view.width - Theme.contentOffset.doubled)
        self.errorLabel.centerOnXAndY()

        self.instructionLabel.setSize(withWidth: self.view.width - Theme.contentOffset.doubled)
        self.instructionLabel.centerOnX()
        self.instructionLabel.centerY = self.gradientView.centerY
    }

    private func handle(state: PhotoState) {
        switch state {
        case .initial:
            delay(0.5) {
                self.handleInitialState()
            }
        case .scanEyesOpen, .scanEyesClosed:
            self.handleScanState()
        case .captureEyesOpen, .captureEyesClosed:
            self.handleCaptureState()
        case .error:
            self.handleErrorState()
        case .finish:
            Task {
                await self.handleFinishState()
            }
        }

        self.view.layoutNow()
    }

    private func handleInitialState() {

        self.button.set(style: .normal(color: .green, text: "Begin"))

        if self.animationView.alpha == 0 {
            UIView.animate(withDuration: Theme.animationDuration, animations: {
                self.animationView.alpha = 1
                self.button.alpha = 1
            }) { (completed) in
                self.animationView.play()
            }
        } else {
            delay(Theme.animationDuration) {
                self.animationView.play()
            }
        }
    }

    private func handleFace(isDetected: Bool) {
        self.errorLabel.setText("No face detected")
        self.view.layoutNow()

        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
            self.errorLabel.alpha = isDetected ? 0.0 : 1.0
            self.instructionLabel.alpha = isDetected ? 1.0 : 0.0
            self.cameraVC.previewLayer.opacity = isDetected ? 1.0 : 0.5
        } completion: { completed in

        }
    }

    private func handleEyesClosed() {
        self.errorLabel.setText("Please close your eyes")
        self.view.layoutNow()

        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
            self.errorLabel.alpha = 1.0
            self.instructionLabel.alpha = 0.0
            self.cameraVC.previewLayer.opacity = 0.5
        } completion: { completed in
            UIView.animate(withDuration: 0.2, delay: 1.5, options: []) {
                self.errorLabel.alpha = 0.0
                self.instructionLabel.alpha = 1.0
                self.cameraVC.previewLayer.opacity = 1.0
            } completion: { _ in
                self.currentState = .scanEyesClosed
            }
        }
    }

    private func handleScanState() {
        if !self.cameraVC.session.isRunning {
            self.cameraVC.begin()
        }

        if self.currentState == .scanEyesOpen {
            self.instructionLabel.setText("Tap to take photo")
        } else if self.currentState == .scanEyesClosed {
            self.instructionLabel.setText("Close your eyes and tap to take photo")
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.button.alpha = 0
            self.animationView.alpha = 0
            self.instructionLabel.alpha = 1
        }) { (completed) in

        }
    }

    private func handleCaptureState() {
        self.cameraVC.capturePhoto()

        UIView.animate(withDuration: 0.2) {
            self.instructionLabel.alpha = 0.0
        }
    }

    private func handleEyesClosedCaptureState() {
        self.cameraVC.capturePhoto()

        self.button.set(style: .normal(color: .purple, text: "Continue"))

        UIView.animate(withDuration: 0.2) {
            self.button.alpha = 1.0
            self.instructionLabel.alpha = 0.0
        }
    }

    private func handleErrorState() {
        self.complete(with: .failure(ClientError.message(detail: "There was a problem. Please try again.")))
    }

    @MainActor
    private func handleFinishState() async {
        await self.button.handleEvent(status: .loading)
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }

        self.complete(with: .success(()))
    }

    private func updateUser(with image: UIImage) async {
        guard let currentUser = User.current(), let data = image.previewData else { return }

        if self.currentState == .captureEyesOpen {
            let file = PFFileObject(name:"small_image.jpeg", data: data)
            currentUser.smallImage = file
        } else if self.currentState == .captureEyesClosed {
            let file = PFFileObject(name:"focus_image.jpeg", data: data)
            currentUser.focusImage = file
        }

        await self.button.handleEvent(status: .loading)

        do {
            try await currentUser.saveToServer()
            self.scheduleToast(with: image)
            await self.button.handleEvent(status: .complete)

            if self.currentState == .captureEyesOpen {
                self.currentState = .scanEyesClosed
            } else if self.currentState == .captureEyesClosed {
                self.currentState = .finish
            }
        } catch {
            await self.button.handleEvent(status: .error("Error"))
            self.currentState = .error
        }
    }

    private func scheduleToast(with image: UIImage) {
        let description: Localized

        if self.currentState == .captureEyesOpen {
            description = "You have successfully updated your profile image."
        } else {
            description = "You have successfully updated your focus image."
        }

        let toast = ToastType.basic(identifier: UUID().uuidString,
                                    displayable: image,
                                    title: "Success",
                                    description: description,
                                    deepLink: nil)

        Task {
            await ToastScheduler.shared.schedule(toastType: toast)
        }
    }
}
