//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/29/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

class ExpressionViewController: ViewController {
    
    enum State {
        case initial
        case capture
        case confirm
    }
    
    override var analyticsIdentifier: String? {
        return "SCREEN_EXPRESSION"
    }
    
    let blurView = DarkBlurView()
    private let retakeButton = ThemeButton()
    private let doneButton = ThemeButton()

    private lazy var expressionCaptureVC = ExpressionVideoCaptureViewController()
    let personGradientView = PersonGradientView()
        
    var didCompleteExpression: ((Expression) -> Void)? = nil
    
    @Published private var state: State = .initial
    
    private var data: Data?
    private var videoURL: URL?
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.addSubview(self.blurView)
                
        self.addChild(viewController: self.expressionCaptureVC)
        
        self.view.addSubview(self.personGradientView)
        self.personGradientView.alpha = 0.0

        self.view.addSubview(self.retakeButton)
        self.retakeButton.set(style: .normal(color: .B1, text: "Retake"))
        self.view.addSubview(self.doneButton)
        self.doneButton.set(style: .normal(color: .B2, text: "Done"))
        
        self.setupHandlers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.blurView.expandToSuperviewSize()

        self.expressionCaptureVC.view.expandToSuperviewSize()

        self.personGradientView.frame = self.expressionCaptureVC.faceCaptureVC.cameraViewContainer.frame

        self.doneButton.setSize(with: 250)
        self.doneButton.centerOnX()
        self.doneButton.pinToSafeAreaBottom()

        self.retakeButton.setSize(with: 250)
        self.retakeButton.centerOnX()
        self.retakeButton.match(.bottom, to: .top, of: self.doneButton, offset: .negative(.standard))
    }
    
    private func setupHandlers() {
        self.expressionCaptureVC.faceCaptureVC.didCaptureVideo = { [unowned self] videoURL in
            self.videoURL = videoURL

            Task.onMainActor {
                self.expressionCaptureVC.faceCaptureVC.stopSession()

                self.state = .confirm
            }
        }

        self.expressionCaptureVC.faceCaptureVC.$hasRenderedFaceImage
            .removeDuplicates()
            .mainSink { [unowned self] hasRendered in
                if hasRendered {
                    self.state = .capture
                } else {
                    self.state = .initial
                }
            }.store(in: &self.cancellables)
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.update(for: state)
            }.store(in: &self.cancellables)
        
        if !self.expressionCaptureVC.faceCaptureVC.isSessionRunning {
            self.expressionCaptureVC.faceCaptureVC.beginSession()
        }

        self.retakeButton.addAction(for: .touchUpInside) { [unowned self] in
            if !self.expressionCaptureVC.faceCaptureVC.isSessionRunning {
                self.expressionCaptureVC.faceCaptureVC.beginSession()
            }

            self.expressionCaptureVC.faceCaptureVC.setVideoPreview(with: nil)
            self.state = .capture
        }

        self.doneButton.addAction(for: .touchUpInside) {
            Task {
                guard let expression = await self.createVideoExpression() else { return }
                self.didCompleteExpression?(expression)
            }
        }
    }

    private func update(for state: State) {
        switch state {
        case .initial:
            self.expressionCaptureVC.faceCaptureVC.animate(text: "Scanning...")
            self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 1.0
            self.expressionCaptureVC.faceCaptureVC.animationView.play()

            self.retakeButton.alpha = 0
            self.doneButton.alpha = 0
        case .capture:
            self.expressionCaptureVC.faceCaptureVC.animationView.stop()
            self.expressionCaptureVC.faceCaptureVC.animate(text: "Press and hold to take a video")

            self.expressionCaptureVC.faceCaptureVC.cameraView.alpha = 1

            self.retakeButton.alpha = 0
            self.doneButton.alpha = 0

            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                    self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 0.0
                    self.view.layoutNow()
                }

                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.expressionCaptureVC.view.alpha = 1.0
                }
            })

            UIView.animate(withDuration: 0.1, delay: 0.5, options: []) {
                self.expressionCaptureVC.faceCaptureVC.view.alpha = 1.0
                self.personGradientView.alpha = 0.0
            } completion: { _ in
                if !self.expressionCaptureVC.faceCaptureVC.isSessionRunning {
                    self.expressionCaptureVC.faceCaptureVC.beginSession()
                }
            }
        case .confirm:
            self.expressionCaptureVC.faceCaptureVC.animate(text: "")
            self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 0.0
            self.expressionCaptureVC.faceCaptureVC.animationView.stop()
            self.expressionCaptureVC.faceCaptureVC.cameraView.alpha = 0

            self.retakeButton.alpha = 1
            self.doneButton.alpha = 1

            guard let videoURL = self.videoURL else { break }

            self.expressionCaptureVC.faceCaptureVC.setVideoPreview(with: videoURL)
        }
    }

    private func createVideoExpression() async -> Expression? {
        guard let videoURL = self.videoURL else { return nil }

        let videoData = try! Data(contentsOf: videoURL)

        let expression = Expression()

        expression.author = User.current()
        expression.file = PFFileObject(name: "expression.mov", data: videoData)
        expression.emojiString = nil

        guard let saved = try? await expression.saveToServer() else { return nil }

        return saved
    }
}
