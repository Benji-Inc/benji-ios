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
import Localization

enum PhotoState {
    case initial
    case scanEyesOpen
    case captureEyesOpen
    case didCaptureEyesOpen
    case review
    case error
    case finish
}

class ProfilePhotoCaptureViewController: ViewController, Sizeable, Completable {

    typealias ResultType = Void

    var onDidComplete: ((Result<Void, Error>) -> Void)?

    // MARK: - Views

    lazy var faceCaptureVC = FaceImageCaptureViewController()

    private var tapView = BaseView()
    private let animationView = AnimationView.with(animation: .faceScan)
    private let imageView = DisplayableImageView()
    private let button = ThemeButton()
    private let label = ThemeLabel(font: .medium, textColor: .white)

    let errorView = PhotoErrorView()
    private var errorOffset: CGFloat = -100

    // MARK: - Analytics

    override var analyticsIdentifier: String? {
        return "SCREEN_PHOTO"
    }

    // MARK: - State

    private var previousScanState: PhotoState = .scanEyesOpen
    @Published var currentState: PhotoState = .initial

    // MARK: - Life Cycle

    override func initializeViews() {
        super.initializeViews()

        self.addChild(viewController: self.faceCaptureVC)
        
        self.faceCaptureVC.cameraViewContainer.layer.borderColor = ThemeColor.D6.color.cgColor
        self.faceCaptureVC.cameraViewContainer.backgroundColor = ThemeColor.D6.color.withAlphaComponent(0.1)

        self.view.addSubview(self.errorView)
        self.view.addSubview(self.tapView)
        self.view.addSubview(self.imageView)
        self.imageView.alpha = 0.0

        self.view.addSubview(self.button)
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
        
        self.faceCaptureVC.view.addSubview(self.label)
        
        self.animationView.loopMode = .loop

        self.view.addSubview(self.animationView)
        self.animationView.alpha = 0

        self.setupHandlers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentState = .initial
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.faceCaptureVC.view.expandToSuperviewSize()

        self.faceCaptureVC.cameraViewContainer.roundCorners()

        self.animationView.size = CGSize(width: 140, height: 140)
        self.animationView.center = self.faceCaptureVC.cameraViewContainer.center

        self.errorView.bottom = self.view.height - self.errorOffset
        
        self.tapView.expandToSuperviewSize()
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()

        if self.currentState == .review {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
        
        self.label.setSize(withWidth: Theme.getPaddedWidth(with: self.view.width))
        self.label.centerOnX()
        self.label.top = self.faceCaptureVC.view.height * 0.4 + 20 + Theme.ContentOffset.long.value
    }
    
    private func setupHandlers() {
        
        self.button.didSelect { [unowned self] in
            Task {
                guard let image = self.imageView.displayable?.image else { return }
                await self.updateUser(with: image)
            }
        }
        
        self.tapView.didSelect { [unowned self] in
            switch self.currentState {
            case .initial:
                self.currentState = .scanEyesOpen
            case .scanEyesOpen:
                guard self.faceCaptureVC.faceDetected else { return }
                self.currentState = .captureEyesOpen
            case .captureEyesOpen, .didCaptureEyesOpen:
                break
            case .review:
                self.currentState = .scanEyesOpen
            case .finish:
                break
            case .error:
                break
            }
        }

        self.faceCaptureVC.didCapturePhoto = { [unowned self] image in
            switch self.currentState {
            case .captureEyesOpen:
                if self.faceCaptureVC.isSmiling {
                    self.currentState = .didCaptureEyesOpen
                    self.animateError(with: nil, show: false)
                    self.imageView.displayable = image
                    self.currentState = .review
                } else {
                    // If the user needs to smile, let them know.
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

        self.faceCaptureVC.$faceDetected
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
        case .review:
            self.handleReviewState()
        case .finish:
            Task {
                await self.handleFinishState()
            }.add(to: self.autocancelTaskPool)
        }
        
        self.updateText(for: state)

        self.view.layoutNow()
    }
    
    private func updateText(for state: PhotoState) {
        let text: Localized
        switch state {
        case .initial:
            text = LocalizedString(id: "",
                                   arguments: [],
                                   default: "Scanning...")
        case .scanEyesOpen:
            text = "Smile and tap the screen."
        case .didCaptureEyesOpen:
            text = "Good one!"
        case .captureEyesOpen:
            text = "Try again"
        case .review:
            text = "Looking good! 😄"
        case .error:
            text = ""
        case .finish:
            text = ""
        }
        
        self.label.setText(text)
    }
    
    private func handleInitialState() {
        if self.animationView.alpha == 0 {
            UIView.animate(withDuration: Theme.animationDurationStandard, animations: {
                self.animationView.alpha = 1
                self.view.setNeedsLayout()
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
            self.faceCaptureVC.cameraView.alpha = isDetected ? 1.0 : 0.25
        } completion: { completed in

        }
    }

    private func handleNotSmiling() {
        self.animateError(with: "Don't forget to smile.", show: true)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: []) {
            self.faceCaptureVC.cameraView.alpha = 0.5
        } completion: { completed in
            UIView.animate(withDuration: 0.2, delay: 0.0, options: []) {
                self.faceCaptureVC.cameraView.alpha = 1.0
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
        if !self.faceCaptureVC.isSessionRunning {
            self.faceCaptureVC.beginSession()
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.imageView.alpha = 0
            self.animationView.alpha = 0
            self.view.layoutNow()
        })
    }

    private func handleCaptureState() {
        self.faceCaptureVC.capturePhoto()
    }
    
    private func handleReviewState() {
        
        if self.faceCaptureVC.isSessionRunning {
            self.faceCaptureVC.stopSession()
        }
        
        self.label.setText("Tap again to retake")
        
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.imageView.alpha = 1.0
            self.view.layoutNow()
        }
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
        guard let currentUser = User.current(), let data = image.previewData else { return }
        
        let nowString = Date.now.ISO8601Format().removeAllNonNumbers()
    
        let file = PFFileObject(name:"\(nowString).heic", data: data)
        currentUser.smallImage = file

        do {
            await self.button.handleEvent(status: .loading)
            try await currentUser.saveToServer()
            await ToastScheduler.shared.schedule(toastType: .success(ImageSymbol.personCropCircle.image, "Profile picture updated"))
            await self.button.handleEvent(status: .complete)
            
            self.currentState = .finish
        } catch {
            self.animateError(with: "There was an error uploading your photo.", show: true)
        }
    }
}


class PhotoErrorView: BaseView {

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
