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
    
    private let doneButton = ThemeButton()
    
    lazy var expressionCaptureVC = ExpressionVideoCaptureViewController()
    
    var didCompleteExpression: ((Expression) -> Void)? = nil
    
    @Published var state: State = .initial
    
    private var data: Data?
    private var videoURL: URL?
    
    static let maxDuration: TimeInterval = 3.0
    
    var animation = CABasicAnimation(keyPath: "strokeEnd")
    
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        let color = self.favoriteType?.emotion.color.cgColor ?? ThemeColor.D6.color.cgColor
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
    
    @Published var favoriteType: FavoriteType?
    
    init(with favoriteType: FavoriteType?) {
        self.favoriteType = favoriteType
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
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
        self.expressionCaptureVC.videoPreviewView.shouldPlay = true
        
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
        
        self.$favoriteType.mainSink { [unowned self] type in
            guard let type = type else { return }
            self.expressionCaptureVC.set(favoriteType: type)
            self.view.setNeedsLayout()
        }.store(in: &self.cancellables)
        
        self.expressionCaptureVC.didCaptureVideo = { [unowned self] videoURL in
            self.videoURL = videoURL
            
            Task.onMainActor {
                self.expressionCaptureVC.stopSession()
                self.state = .confirm
            }
        }
        
        self.expressionCaptureVC.$hasRenderedFaceImage
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
                guard let expression = await self.createVideoExpression() else { return }
                self.didCompleteExpression?(expression)
            }
        }
        
        if !self.expressionCaptureVC.isSessionRunning {
            self.expressionCaptureVC.beginSession()
        }
    }
    
    private func update(for state: State) {
        switch state {
        case .initial:
            self.expressionCaptureVC.favoriteLabel.alpha = 0.0
            self.expressionCaptureVC.animate(text: "Scanning...")
            self.expressionCaptureVC.animationView.alpha = 1.0
            self.expressionCaptureVC.animationView.play()
        case .capture:
            self.expressionCaptureVC.animationView.stop()
            self.expressionCaptureVC.animate(text: "Press and Hold")
            self.expressionCaptureVC.setVideoPreview(with: nil)
            
            self.expressionCaptureVC.setVideoPreview(with: nil)
            
            let duration: TimeInterval = 0.25
            
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                    self.expressionCaptureVC.favoriteLabel.alpha = 1.0
                    self.expressionCaptureVC.cameraView.alpha = 1
                    self.expressionCaptureVC.animationView.alpha = 0.0
                    self.view.layoutNow()
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.expressionCaptureVC.view.alpha = 1.0
                }
            })
            
            UIView.animate(withDuration: 0.1, delay: duration, options: []) {
                self.expressionCaptureVC.cameraViewContainer.layer.borderColor = ThemeColor.B1.color.cgColor
                self.expressionCaptureVC.view.alpha = 1.0
            } completion: { _ in
                if !self.expressionCaptureVC.isSessionRunning {
                    self.expressionCaptureVC.beginSession()
                }
            }
        case .confirm:
            self.expressionCaptureVC.animate(text: "Tap to retake")
            self.expressionCaptureVC.animationView.alpha = 0.0
            self.expressionCaptureVC.animationView.stop()
            
            self.stopRecordingAnimation()
            
            guard let videoURL = self.videoURL else { break }
            
            self.expressionCaptureVC.setVideoPreview(with: videoURL)
            
            UIView.animate(withDuration: Theme.animationDurationFast) {
                if let favoriteType = self.favoriteType {
                    self.expressionCaptureVC.cameraViewContainer.layer.borderColor = favoriteType.emotion.color.cgColor
                }
                self.expressionCaptureVC.favoriteLabel.alpha = 0.0
                self.expressionCaptureVC.favoriteLabel.transform = .identity
                self.expressionCaptureVC.cameraView.alpha = 0.0
                self.view.layoutNow()
            }
        }
    }
    
    private func createVideoExpression() async -> Expression? {
        guard let videoURL = self.videoURL else { return nil }
        
        let videoData = try! Data(contentsOf: videoURL)
        
        // If an expression exists, then update it
        if let type = self.favoriteType, let expression = try? await type.getExpression() {
            
            expression.file = PFFileObject(name: "expression.mov", data: videoData)
            guard let saved = try? await expression.saveToServer() else { return nil }
            return saved
            
        // Otherwise create a new one
        } else {
            let expression = Expression()
            
            if let favoriteType = self.favoriteType {
                expression.emotionCounts = [favoriteType.emotion: 1]
                expression.isFavorite = true
            }
            expression.author = User.current()
            expression.file = PFFileObject(name: "expression.mov", data: videoData)
            expression.emojiString = nil
            
            guard let saved = try? await expression.saveToServer() else { return nil }
            
            return saved
        }
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

extension ExpressionViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        self.stopRecordingAnimation()
        self.expressionCaptureVC.endVideoCapture()
        self.state = .capture
        return true
    }
}
