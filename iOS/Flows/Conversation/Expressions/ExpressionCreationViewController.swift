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
    
    private lazy var expressionPhotoVC = ExpressionPhotoCaptureViewController()
    private lazy var emotionsVC = EmotionsViewController()
    
    let leftButton = ThemeButton()
    let leftImageView = UIImageView(image: UIImage(systemName: "arrow.backward.circle.fill"))
    
    let rightButton = ThemeButton()
    let rightImageView = UIImageView(image: UIImage(systemName: "arrow.right.circle.fill"))

    let doneButton = ThemeButton()
    
    private let scrollView = UIScrollView()
    
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
        
        self.scrollView.isScrollEnabled = false
        self.scrollView.isPagingEnabled = true
        
        self.view.addSubview(self.scrollView)
        
        self.addChild(viewController: self.expressionPhotoVC, toView: self.scrollView)
        self.expressionPhotoVC.onDidComplete = { [unowned self] result in
            switch result {
            case .success(let expressionData):
                guard let expressionData = expressionData else {
                    return
                }
                self.imageURL = try? AttachmentsManager.shared.createTemporaryHeicURL(for: expressionData)
                self.state = .review
            case .failure:
                break
            }
        }
        
        self.addChild(viewController: self.emotionsVC, toView: self.scrollView)
        
        self.view.set(backgroundColor: .B0)
        self.view.addSubview(self.bottomGradientView)
        
        self.view.addSubview(self.leftImageView)
        self.leftImageView.tintColor = ThemeColor.white.color
        self.view.addSubview(self.leftButton)
        self.leftButton.didSelect { [unowned self] in
            self.state = .review
        }
        
        self.view.addSubview(self.rightImageView)
        self.rightImageView.tintColor = ThemeColor.white.color 
        self.view.addSubview(self.rightButton)
        self.rightButton.didSelect { [unowned self] in
            self.state = .emotionSelection
        }
        
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.scrollView.expandToSuperviewSize()
        
        self.leftImageView.squaredSize = Theme.buttonHeight
        self.leftImageView.pinToSafeAreaLeft()
        self.leftImageView.pinToSafeAreaBottom()
        
        self.leftButton.frame = self.leftImageView.frame
        
        self.rightImageView.squaredSize = Theme.buttonHeight
        self.rightImageView.pinToSafeAreaRight()
        self.rightImageView.pinToSafeAreaBottom()
        
        self.rightButton.frame = self.rightImageView.frame
        
        self.doneButton.height = Theme.buttonHeight
        self.doneButton.width = 125
        self.doneButton.pinToSafeAreaRight()
        self.doneButton.pinToSafeAreaBottom()
        
        self.expressionPhotoVC.view.expandToSuperviewHeight()
        self.expressionPhotoVC.view.width = self.view.width
        self.expressionPhotoVC.view.pin(.top)
        self.expressionPhotoVC.view.pin(.left)
        
        self.emotionsVC.view.expandToSuperviewHeight()
        self.emotionsVC.view.width = self.view.width
        self.emotionsVC.view.pin(.top)
        self.emotionsVC.view.match(.left, to: .right, of: self.expressionPhotoVC.view)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
        
        self.scrollView.contentSize = CGSize(width: self.emotionsVC.view.right,
                                             height: self.view.height)
    }
    
    private func update(for state: State) {
        switch state {
        case .capture:
            self.rightButton.isVisible = true
            self.rightImageView.isVisible = true
            self.leftButton.isVisible = false
            self.leftImageView.isVisible = false
            self.doneButton.isVisible = false
        case .review:
            self.rightButton.isVisible = true
            self.rightImageView.isVisible = true
            self.leftButton.isVisible = false
            self.leftImageView.isVisible = false
            self.doneButton.isVisible = false
            self.scrollView.scrollHorizontallyTo(view: self.expressionPhotoVC.view, animated: true)
        case .emotionSelection:
            self.rightButton.isVisible = false
            self.rightImageView.isVisible = false
            self.leftButton.isVisible = true
            self.leftImageView.isVisible = true
            self.doneButton.isVisible = true
            self.scrollView.scrollHorizontallyTo(view: self.emotionsVC.view, animated: true)
        }
    }
}
