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
    
    override var analyticsIdentifier: String? {
        return "SCREEN_EXPRESSION"
    }
    
    let blurView = DarkBlurView()

    private lazy var commonExpressionsVC = CommonExpressionsViewController()
    private lazy var expressionPhotoVC = ExpressionPhotoCaptureViewController()
    private let personGradientView = PersonGradientView()
        
    var didCompleteExpression: ((Expression) -> Void)? = nil
            
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
                
        self.addChild(viewController: self.commonExpressionsVC)
        
        self.view.addSubview(self.personGradientView)
        self.personGradientView.alpha = 0.0
        
        self.setupHandlers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.commonExpressionsVC.loadInitialData()
    }
    
    private func setupHandlers() {
        
        self.commonExpressionsVC.$selectedItems.mainSink { [unowned self] items in
            guard let first = items.first, case CommonExpressionsDataSource.ItemType.expression(let model) = first else { return }
            self.handleSelected(item: model)
        }.store(in: &self.cancellables)
        
        self.expressionPhotoVC.faceCaptureVC.didCapturePhoto = { [unowned self] image in
            guard let data = image.previewData else { return }
            self.data = data
                        
            self.expressionPhotoVC.faceCaptureVC.view.alpha = 0.0
            self.personGradientView.alpha = 1.0
            self.personGradientView.set(displayable: UIImage(data: data))
            self.expressionPhotoVC.animate(text: "Tap again to retake")
            self.expressionPhotoVC.faceCaptureVC.stopSession()
            
            self.personGradientView.displayable = UIImage(data: data)
        }
        
        self.personGradientView.didSelect { [unowned self] in
            // Retake?
        }
        
//        self.doneButton.didSelect { [unowned self] in
//            Task {
//                await self.createExpression()
//            }
//        }
        
        
//        self.emotionsVC.$selectedEmotions.mainSink { [unowned self] emotions in
//            var emotionsCounts: [Emotion: Int] = [:]
//            emotions.forEach { emotion in
//                emotionsCounts[emotion] = 1
//            }
//            self.emotionCollectionView.setEmotionsCounts(emotionsCounts, animated: true)
//            self.personGradientView.set(emotionCounts: emotionsCounts)
//        }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        
        self.expressionPhotoVC.view.expandToSuperviewSize()
        
        self.personGradientView.frame = self.expressionPhotoVC.faceCaptureVC.cameraViewContainer.frame
        
        self.commonExpressionsVC.view.expandToSuperviewWidth()
        self.commonExpressionsVC.view.height = 100
        self.commonExpressionsVC.view.centerOnY()
    }
    
    func handleSelected(item: ExpressionModel) {
        if let existing = item.existingExpression {
            // Show
        } else {
            // Capture
        }
    }
    
    private func createExpression() async {
        guard let data = self.data else { return }

        let expression = Expression()
        
        expression.author = User.current()
        expression.file = PFFileObject(name: "expression.heic", data: data)
        
        guard let saved = try? await expression.saveToServer() else { return }
        
        self.didCompleteExpression?(saved)
    }
    
//    private func update(for state: State) {
//        switch state {
//        case .capture:
//            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, animations: {
//
//                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
//                    self.view.layoutNow()
//                }
//
//                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
//                    self.expressionPhotoVC.view.alpha = 1.0
//                }
//            })
//
//            UIView.animate(withDuration: 0.1, delay: 0.5, options: []) {
//                self.expressionPhotoVC.faceCaptureVC.view.alpha = 1.0
//                self.personGradientView.alpha = 0.0
//            } completion: { _ in
//                if !self.expressionPhotoVC.faceCaptureVC.isSessionRunning {
//                    self.expressionPhotoVC.faceCaptureVC.beginSession()
//                }
//            }
//
//        case .emotionSelection:
//            UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, animations: {
//
//                UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.75) {
//                    self.view.layoutNow()
//                }
//
//                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
//                    self.expressionPhotoVC.view.alpha = 0.0
//                }
//            })
//        }
//    }
}
