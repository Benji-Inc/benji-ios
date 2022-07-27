//
//  MomentCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Parse

// Capture Expression
// Capture Media
// Create conversation of type moment
// Add all connected users to conversation

class MomentCaptureViewController: ViewController {
    
    enum State {
        case initial
        case capture
        case confirm
    }
    
    override var analyticsIdentifier: String? {
        return "SCREEN_MOMENT"
    }
    
    let blurView = DarkBlurView()
    
    private let doneButton = ThemeButton()
    
    lazy var expressionCaptureVC = ExpressionVideoCaptureViewController()
    lazy var momentCatureVC = MomentVideoCaptureViewController()
    
    var didCompleteMoment: ((Moment) -> Void)? = nil
    
    @Published var state: State = .initial
    
    private var expressionData: Data?
    private var expressionURL: URL?
    
    private var momentData: Data?
    private var momentURL: URL?
    
    static let maxDuration: TimeInterval = 3.0
    
    var animation = CABasicAnimation(keyPath: "strokeEnd")
    
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        let color = ThemeColor.D6.color.cgColor
        shapeLayer.fillColor = ThemeColor.clear.color.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 4
        shapeLayer.shadowColor = color
        shapeLayer.shadowRadius = 5
        shapeLayer.shadowOffset = .zero
        shapeLayer.shadowOpacity = 1.0
        return shapeLayer
    }()
            
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.presentationController?.delegate = self
                
        self.view.addSubview(self.blurView)
        
        self.addChild(viewController: self.expressionCaptureVC)
        self.expressionCaptureVC.faceCaptureVC.videoPreviewView.shouldPlay = true
        
        self.view.addSubview(self.doneButton)
        self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
                        
        self.setupHandlers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.expressionCaptureVC.view.expandToSuperviewSize()
                
        self.doneButton.setSize(with: self.view.width)
        self.doneButton.centerOnX()
                
        if self.state == .confirm {
            self.doneButton.pinToSafeAreaBottom()
        } else {
            self.doneButton.top = self.view.height
        }
    }
    
    private func setupHandlers() {
        
        self.expressionCaptureVC.faceCaptureVC.didCaptureVideo = { [unowned self] videoURL in
            self.expressionURL = videoURL
            
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
        
        self.view.didSelect { [unowned self] in
            guard self.state == .confirm else { return }
            self.state = .capture
        }
        
        self.doneButton.didSelect { [unowned self] in
            Task {
                guard let moment = await self.createMoment() else { return }
                self.didCompleteMoment?(moment)
            }
        }
        
        if !self.expressionCaptureVC.faceCaptureVC.isSessionRunning {
            self.expressionCaptureVC.faceCaptureVC.beginSession()
        }
        
        self.expressionCaptureVC.faceCaptureVC.$videoCaptureState
            .removeDuplicates()
            .mainSink { [unowned self] state in
                
        }.store(in: &self.cancellables)
    }
    
    private func update(for state: State) {
        switch state {
        case .initial:
            self.expressionCaptureVC.faceCaptureVC.animate(text: "Scanning...")
            self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 1.0
            self.expressionCaptureVC.faceCaptureVC.animationView.play()
        case .capture:
            self.expressionCaptureVC.faceCaptureVC.animationView.stop()
            self.expressionCaptureVC.faceCaptureVC.animate(text: "Press and Hold")
            self.expressionCaptureVC.faceCaptureVC.setVideoPreview(with: nil)
            
            self.expressionCaptureVC.faceCaptureVC.setVideoPreview(with: nil)
            
            let duration: TimeInterval = 0.25
            
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                    self.expressionCaptureVC.faceCaptureVC.cameraView.alpha = 1
                    self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 0.0
                    self.view.layoutNow()
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.expressionCaptureVC.view.alpha = 1.0
                }
            })
            
            UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                self.expressionCaptureVC.faceCaptureVC.cameraViewContainer.layer.borderColor = ThemeColor.B1.color.cgColor
                self.expressionCaptureVC.faceCaptureVC.view.alpha = 1.0
            } completion: { _ in
                if !self.expressionCaptureVC.faceCaptureVC.isSessionRunning {
                    self.expressionCaptureVC.faceCaptureVC.beginSession()
                }
            }
        case .confirm:
            self.expressionCaptureVC.faceCaptureVC.animate(text: "Tap to retake")
            self.expressionCaptureVC.faceCaptureVC.animationView.alpha = 0.0
            self.expressionCaptureVC.faceCaptureVC.animationView.stop()
            
            self.stopRecordingAnimation()
            
            guard let videoURL = self.expressionURL else { break }
            
            self.expressionCaptureVC.faceCaptureVC.setVideoPreview(with: videoURL)
            
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.expressionCaptureVC.faceCaptureVC.cameraView.alpha = 0.0
                self.view.layoutNow()
            }
        }
    }
    
    private func createMoment() async -> Moment? {
        guard let expressionURL = self.expressionURL, let momentURL = self.momentURL else { return nil }
        
        let expressionData = try! Data(contentsOf: expressionURL)
        let momentData = try! Data(contentsOf: momentURL)
        
        let expression = Expression()
        
        expression.author = User.current()
        expression.file = PFFileObject(name: "expression.mov", data: expressionData)
        expression.emojiString = nil
        
        guard let savedExpression = try? await expression.saveToServer() else { return nil }
        
        #warning("Add conversation id to moment creation")
        
        let moment = Moment()
        moment.expression = savedExpression
        moment.conversationId = "Some conversation ID"
        moment.author = User.current()
        moment.file = PFFileObject(name: "moment.mov", data: momentData)
        
        guard let savedMoment = try? await moment.saveToServer() else { return nil }

        return savedMoment
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard self.state == .capture else { return }
        
        if let _ = touches.first?.view as? VideoView {
            return
        }
        
        self.beginRecordingAnimation()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard self.state == .capture else { return }
        
        self.stopRecordingAnimation()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard self.state == .capture else { return }
        
        self.stopRecordingAnimation()
    }
}

extension MomentCaptureViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        self.stopRecordingAnimation()
        self.expressionCaptureVC.endVideoCapture()
        self.state = .capture
        return true
    }
}

