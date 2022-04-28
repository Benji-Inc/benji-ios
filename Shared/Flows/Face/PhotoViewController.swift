//
//  LoginProfilePhotoViewController.swift
//  Benji
//
//  Created by Benji Dodgson on 8/12/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Lottie
import UIKit
import Combine
import AVFoundation

enum PhotoState {
    case initial
    case scanEyesOpen
    case captureEyesOpen
    case didCaptureEyesOpen
    case error
    case finish
}

class PhotoViewController: ViewController, Sizeable, Completable {

    typealias ResultType = Void

    var onDidComplete: ((Result<Void, Error>) -> Void)?

    let errorView = ErrorView()
    private var errorOffset: CGFloat = -100

    lazy var cameraVC = FaceImageCaptureViewController()
    
    override var analyticsIdentifier: String? {
        return "SCREEN_PHOTO"
    }

    private lazy var smilingDisclosureVC: FaceDisclosureViewController = {
        let vc = FaceDisclosureViewController(with: .smiling)
        vc.dismissHandlers.append { [unowned self] in
            self.currentState = .finish
        }
        vc.button.didSelect { [unowned self] in
            vc.dismiss(animated: true, completion: nil)
        }
        return vc
    }()

    private var tapView = BaseView()

    private let animationView = AnimationView.with(animation: .faceScan)
    private var previousScanState: PhotoState = .scanEyesOpen

    @Published var currentState: PhotoState = .initial

    override func initializeViews() {
        super.initializeViews()

        self.animationView.loopMode = .loop

        self.view.addSubview(self.animationView)
        self.animationView.alpha = 0
        self.addChild(viewController: self.cameraVC)

        self.view.addSubview(self.errorView)
        self.view.addSubview(self.tapView)

        self.tapView.didSelect { [unowned self] in
            switch self.currentState {
            case .initial:
                self.currentState = .scanEyesOpen
            case .scanEyesOpen:
                guard self.cameraVC.faceDetected else { return }
                self.currentState = .captureEyesOpen
            case .captureEyesOpen, .didCaptureEyesOpen:
                break
            case .finish:
                break
            case .error:
                break
            }
        }

        self.cameraVC.didCapturePhoto = { [unowned self] image in
            switch self.currentState {
            case .captureEyesOpen:
                if self.cameraVC.isSmiling {
                    self.currentState = .didCaptureEyesOpen
                    self.animateError(with: nil, show: false)
                    Task {
                        await self.updateUser(with: image)
                    }.add(to: self.autocancelTaskPool)
                } else {
                    self.handleNotSmiling()
                }
            default:
                break
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
                switch self.currentState {
                case .scanEyesOpen, .error:
                    self.handleFace(isDetected: faceDetected)
                default:
                    break
                }
            }).store(in: &self.cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.currentState = .initial
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.animationView.size = CGSize(width: 140, height: 140)
        self.animationView.centerOnX()
        self.animationView.centerY = self.view.centerY * 0.95

        self.errorView.bottom = self.view.height - self.errorOffset
        
        self.tapView.expandToSuperviewSize()
        
        self.cameraVC.view.expandToSuperviewSize()
    }

    private func handle(state: PhotoState) {
        switch state {
        case .initial:
            delay(0.5) {
                self.handleInitialState()
            }
        case .scanEyesOpen:
            self.previousScanState = state
            self.handleScanState()
        case .captureEyesOpen:
            self.handleCaptureState()
        case .error, .didCaptureEyesOpen:
            break
        case .finish:
            Task {
                await self.handleFinishState()
            }.add(to: self.autocancelTaskPool)
        }

        self.view.layoutNow()
    }

    private func handleInitialState() {
        if self.animationView.alpha == 0 {
            UIView.animate(withDuration: Theme.animationDurationStandard, animations: {
                self.animationView.alpha = 1
            }) { (completed) in
                self.animationView.play()
            }
        } else {
            delay(Theme.animationDurationStandard) {
                self.animationView.play()
            }
        }
    }

    private func handleFace(isDetected: Bool) {
        if isDetected {
            self.currentState = self.previousScanState
        }

        self.animateError(with: "No face detected.", show: !isDetected)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
            self.cameraVC.cameraView.alpha = isDetected ? 1.0 : 0.25
        } completion: { completed in

        }
    }

    private func handleNotSmiling() {
        self.animateError(with: "Don't forget to smile.", show: true)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
            self.cameraVC.cameraView.alpha = 0.5
        } completion: { completed in
            UIView.animate(withDuration: 0.2, delay: 0.0, options: []) {
                self.cameraVC.cameraView.alpha = 1.0
            } completion: { _ in
                Task {
                    await Task.sleep(seconds: 2.0)
                    self.currentState = .scanEyesOpen
                    self.animateError(with: nil, show: false)
                }
            }
        }
    }

    private func handleScanState() {
        if !self.cameraVC.session.isRunning {
            self.cameraVC.begin()
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.animationView.alpha = 0
            self.cameraVC.faceBoxView.alpha = 1.0
            self.view.layoutNow()
        })
    }

    private func handleCaptureState() {
        self.cameraVC.capturePhoto()
    }

    private func animateError(with message: String?, show: Bool) {
        if let msg = message {
            self.errorView.label.setText(msg)
            self.errorView.label.layoutNow()
        }

        self.errorOffset = show ? 120 : -100
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        }
    }

    @MainActor
    private func handleFinishState() async {
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }

        self.complete(with: .success(()))
    }

    private func updateUser(with image: UIImage) async {
        guard let data = image.previewPngData else { return }
                
        do {
            await UIView.awaitAnimation(with: .fast, animations: {
                self.cameraVC.faceBoxView.alpha = 0.0
            })
            try await self.presentDisclosure(with: data)
        } catch {
            self.animateError(with: "There was an error uploading your photo.", show: true)
        }
    }

    @MainActor
    private func presentDisclosure(with data: Data) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            switch self.currentState {
            case .didCaptureEyesOpen:
                self.present(self.smilingDisclosureVC, animated: true, completion: { [unowned self] in
                    Task {
                        do {
                            try await self.smilingDisclosureVC.updateUser(with: data)
                            continuation.resume(returning: ())
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                })
            default:
                continuation.resume(returning: ())
            }
        }
    }
}

class ErrorView: BaseView {

    let label = ThemeLabel(font: .smallBold, textColor: .red)
    private let blurView = BlurView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.blurView)
        self.addSubview(self.label)
        self.backgroundColor = ThemeColor.red.color.withAlphaComponent(0.8)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        #if !NOTIFICATION
        guard let superview = UIWindow.topWindow() else { return }
        self.label.setSize(withWidth: superview.width - Theme.contentOffset.doubled)

        self.size = CGSize(width: self.label.width + Theme.contentOffset, height: self.label.height + Theme.contentOffset)

        self.label.centerOnXAndY()
        self.centerOnX()

        self.blurView.expandToSuperviewSize()

        self.roundCorners()
        #endif
    }
}
