//
//  ExpressionCaptureViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/29/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

class ExpressionCreationViewController: ViewController {
    
    enum State {
        case capture
        case review
        case emotionSelection
    }
    
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)
    
    let blurView = DarkBlurView()
    private lazy var emotionCollectionView = EmotionCircleCollectionView(cellDiameter: 100)

    private lazy var expressionPhotoVC = ExpressionPhotoCaptureViewController()
    private lazy var emotionsVC = EmotionsViewController()

    let doneButton = ThemeButton()
        
    var didCompleteExpression: ((Expression) -> Void)? = nil
    
    @Published private var state: State = .capture
    
    private var imageURL: URL?
    
    override func initializeViews() {
        super.initializeViews()
        
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            let sheet = pop.adaptiveSheetPresentationController
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        
        self.view.addSubview(self.emotionCollectionView)
        self.view.addSubview(self.blurView)
        
        self.expressionPhotoVC.faceCaptureVC.didCapturePhoto = { [unowned self] image in
            guard let imageData = image.previewData else { return }
            self.expressionPhotoVC.faceCaptureVC.view.isVisible = false
            self.expressionPhotoVC.personGradientView.isVisible = true
            self.expressionPhotoVC.personGradientView.set(displayable: UIImage(data: imageData))
            self.expressionPhotoVC.animate(text: "Tap again to retake")
            self.expressionPhotoVC.faceCaptureVC.stopSession()
            
            self.emotionsVC.personGradientView.set(displayable: UIImage(data: imageData))
            
            self.state = .emotionSelection
        }
                
        self.addChild(viewController: self.expressionPhotoVC)
        self.expressionPhotoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let expressionData):
                guard let expressionData = expressionData else {
                    return
                }
                self.imageURL = try? AttachmentsManager.shared.createTemporaryHeicURL(for: expressionData)
                //self.state = .emotionSelection
            case .failure:
                break
            }
        }
        
        self.addChild(viewController: self.emotionsVC)
        self.emotionsVC.view.alpha = 0
        
        self.view.set(backgroundColor: .B0)
        self.view.addSubview(self.bottomGradientView)
        
        self.view.addSubview(self.doneButton)
        self.doneButton.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
        
        self.doneButton.didSelect { [unowned self] in
            var emotionCounts: [Emotion: Int] = [:]
            self.emotionsVC.selectedEmotions.forEach { emotion in
                emotionCounts[emotion] = 1
            }

            let expression = Expression(imageURL: self.imageURL,
                                        emojiString: nil,
                                        emotionCounts: emotionCounts)
            
            self.didCompleteExpression?(expression)
        }
        
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.update(for: state)
            }.store(in: &self.cancellables)
        
        self.emotionsVC.$selectedEmotions.mainSink { [unowned self] emotions in
            var emotionsCounts: [Emotion: Int] = [:]
            emotions.forEach { emotion in
                emotionsCounts[emotion] = 1
            }
            self.emotionCollectionView.setEmotionsCounts(emotionsCounts, animated: true)
            self.expressionPhotoVC.personGradientView.set(emotionCounts: emotionsCounts)
            self.emotionsVC.personGradientView.set(emotionCounts: emotionsCounts)
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.emotionCollectionView.expandToSuperviewSize()
        self.blurView.expandToSuperviewSize()
        
        self.doneButton.height = Theme.buttonHeight
        self.doneButton.width = 125
        self.doneButton.pinToSafeAreaRight()
        self.doneButton.pinToSafeAreaBottom()
        
        self.expressionPhotoVC.view.expandToSuperviewSize()
        self.emotionsVC.view.expandToSuperviewSize()
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    private func update(for state: State) {
        switch state {
        case .capture:
            self.doneButton.isVisible = false
        case .review:
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.0, animations: {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.emotionsVC.view.alpha = 0.0
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.expressionPhotoVC.view.alpha = 1.0
                }
            })
        case .emotionSelection:
            UIView.animateKeyframes(withDuration: 1.0, delay: 0.0, animations: {

                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                    self.expressionPhotoVC.view.alpha = 0.0
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                    self.emotionsVC.view.alpha = 1.0
                }
            })
        }
    }
}
