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

    private let animationView = AnimationView.with(animation: .faceScan)
    private let button = Button()
    private let instructionLabel = Label(font: .smallBold, textColor: .background4)
    private let errorLabel = Label(font: .regular, textColor: .background4)
    private let gradientView = GradientView(with: [Color.background2.color.cgColor, Color.clear.color.cgColor], startPoint: .bottomCenter, endPoint: .topCenter)

    private var image: UIImage?

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
                self.currentState = .scan
            case .scan:
                break
            case .capture:
                break
            case .error:
                break
            case .finish:
                guard let fixed = self.image else { return }
                Task {
                    await self.saveProfilePicture(image: fixed)
                }
            }
        }

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

                guard self.currentState == .scan else { return }
                if faceDetected {
                    //self.beginButton.set(style: .normal(color: .lightPurple, text: "Capture"))
                } else {
                    //self.beginButton.set(style: .normal(color: .red, text: "NO face detected"))
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
        self.animationView.centerY = self.view.halfHeight * 0.8
        self.animationView.centerOnX()

        self.cameraVC.view.expandToSuperviewSize()

        self.button.setSize(with: self.view.width)
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)
        self.button.centerOnX()

        self.gradientView.height = self.view.height - self.button.top
        self.gradientView.expandToSuperviewWidth()
        self.gradientView.pin(.bottom)
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
            Task {
                await self.handleFinishState()
            }
        }

        self.updateButton(for: state)

        self.view.layoutNow()
    }

    private func updateButton(for state: PhotoState) {

        switch state {
        case .initial:
            self.button.isEnabled = true
            self.button.set(style: .normal(color: .green, text: "Begin"))
        case .scan:
            break
        case .capture:
            break
        case .error:
            break
        case .finish:
            break
        }
    }

    private func handleInitialState() {

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
    }

    private func handleScanState() {
        self.button.isEnabled = false
        self.cameraVC.begin()

        UIView.animate(withDuration: 0.2, animations: {
            self.button.alpha = 0
            self.animationView.alpha = 0
        }) { (completed) in
        }
    }

    private func handleCaptureState() {
        self.cameraVC.capturePhoto()
    }

    private func handleErrorState() {
        self.complete(with: .failure(ClientError.message(detail: "There was a problem. Please try again.")))
    }

    @MainActor
    private func handleFinishState() async {
        self.complete(with: .success(()))
        await self.button.handleEvent(status: .loading)
        self.cancellables.forEach { (cancellable) in
            cancellable.cancel()
        }
    }

    private func update(image: UIImage) {
        self.cameraVC.stop()

        self.image = image
    }

    private func saveProfilePicture(image: UIImage) async {
        guard let currentUser = User.current(), let data = image.previewData else { return }

        let file = PFFileObject(name:"small_image.jpeg", data: data)
        await self.button.handleEvent(status: .loading)

        currentUser.smallImage = file

        do {
            try await currentUser.saveToServer()
            try await ActivateUser().makeRequest(andUpdate: [], viewsToIgnore: [self.view])
            self.currentState = .finish
        } catch {
            self.currentState = .error
        }
    }
}
