//
//  EmotionViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import Localization

class EmotionsViewController: DiffableCollectionViewController<EmotionCategory,
                              EmotionsCollectionViewDataSource.ItemType,
                              EmotionsCollectionViewDataSource> {
    
    let button = ThemeButton()
    private var showButton: Bool = true
    
    private let topGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .topCenter,
                                                  endPoint: .bottomCenter)
                
    private let bottomGradientView = GradientView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
                                                  startPoint: .bottomCenter,
                                                  endPoint: .topCenter)

    init() {
        super.init(with: EmotionsCollectionView())
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
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersGrabberVisible = true 
        }
        
        self.view.set(backgroundColor: .B0)
                        
        self.view.addSubview(self.topGradientView)
        self.view.addSubview(self.bottomGradientView)
        
        self.collectionView.allowsMultipleSelection = true
        
        self.view.addSubview(self.button)
        
        self.$selectedItems.mainSink { [unowned self] items in
            self.updateButton()
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.topGradientView.expandToSuperviewWidth()
        self.topGradientView.height = Theme.ContentOffset.xtraLong.value.doubled
        self.topGradientView.pin(.top)
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
    }
    
    override func layoutCollectionView(_ collectionView: UICollectionView) {
        collectionView.expandToSuperviewWidth()
        collectionView.height = self.view.height * 0.6
        collectionView.pin(.bottom)
    }
    
    private func updateButton() {
        self.button.set(style: .custom(color: .B5, textColor: .T4, text: "Done"))
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.showButton = self.selectedItems.count > 0
            self.view.layoutNow()
        }
    }
    
    override func getAllSections() -> [EmotionCategory] {
        return EmotionCategory.allCases
    }

    override func retrieveDataForSnapshot() async -> [EmotionCategory : [EmotionsCollectionViewDataSource.ItemType]] {
        var data: [EmotionCategory : [EmotionsCollectionViewDataSource.ItemType]] = [:]
        
        EmotionCategory.allCases.forEach { category in
            data[category] = category.emotions.compactMap({ emotion in
                return .emotion(emotion)
            })
        }
//        data[.emotions] = Emotion.allCases.compactMap({ emotion in
//            return .emotion(emotion)
//        })
        return data
    }
}
