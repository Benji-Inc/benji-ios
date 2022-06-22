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
        case capture
        case emotionSelection
    }
    
    override var analyticsIdentifier: String? {
        return "SCREEN_EXPRESSION"
    }
    
    let blurView = DarkBlurView()

    private lazy var expressionPhotoVC = ExpressionPhotoCaptureViewController()
    let personGradientView = PersonGradientView()
        
    var didCompleteExpression: ((Expression) -> Void)? = nil
    
    @Published private var state: State = .capture
    
    private var data: Data?
    
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
                
        self.addChild(viewController: self.expressionPhotoVC)
        
        self.view.addSubview(self.personGradientView)
        self.personGradientView.alpha = 0.0
        
        self.setupHandlers()
    }
    
    private func setupHandlers() {
        
        self.expressionPhotoVC.faceCaptureVC.didCapturePhoto = { [unowned self] image in
            guard let data = image.previewData else { return }
            self.data = data
                        
            self.expressionPhotoVC.faceCaptureVC.view.alpha = 0.0
            self.personGradientView.alpha = 1.0
            self.personGradientView.set(displayable: UIImage(data: data))
            self.expressionPhotoVC.faceCaptureVC.animate(text: "Tap again to retake")
            self.expressionPhotoVC.faceCaptureVC.stopSession()
                        
            self.state = .emotionSelection
            Task {
                await self.createExpression()
            }
        }
        
        self.personGradientView.didSelect { [unowned self] in
            guard self.state == .emotionSelection else { return }
            self.state = .capture
        }
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.update(for: state)
            }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.expressionPhotoVC.view.expandToSuperviewSize()
        
        self.personGradientView.frame = self.expressionPhotoVC.faceCaptureVC.cameraViewContainer.frame
    }
    
    private func createExpression() async {
        guard let data = self.data else { return }
//        var emotionCounts: [Emotion: Int] = [:]
//        self.emotionsVC.selectedEmotions.forEach { emotion in
//            emotionCounts[emotion] = 1
//        }
        
        let expression = Expression()
        
        expression.author = User.current()
        expression.file = PFFileObject(name: "expression.heic", data: data)
        //expression.emotionCounts = emotionCounts
        expression.emojiString = nil
        
        guard let saved = try? await expression.saveToServer() else { return }
        
        self.didCompleteExpression?(saved)
    }
    
    private func update(for state: State) {
        switch state {
        case .capture:
            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, animations: {
                
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                    self.view.layoutNow()
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.expressionPhotoVC.view.alpha = 1.0
                }
            })
            
            UIView.animate(withDuration: 0.1, delay: 0.5, options: []) {
                self.expressionPhotoVC.faceCaptureVC.view.alpha = 1.0
                self.personGradientView.alpha = 0.0
            } completion: { _ in
                if !self.expressionPhotoVC.faceCaptureVC.isSessionRunning {
                    self.expressionPhotoVC.faceCaptureVC.beginSession()
                }
            }
            
        case .emotionSelection:
            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, animations: {
                
                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
                    self.view.layoutNow()
                }

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.expressionPhotoVC.view.alpha = 0.0
                }
            })
        }
    }
}
