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

class EmotionsViewController: DiffableCollectionViewController<EmotionsCollectionViewDataSource.SectionType,
                              EmotionsCollectionViewDataSource.ItemType,
                              EmotionsCollectionViewDataSource> {
    
    let button = ThemeButton()
    private var showButton: Bool = true
    
    @Published var selectedEmotions: [Emotion] = []
    
    private let bottomGradientView = GradientPassThroughView(with: [ThemeColor.B0.color.cgColor, ThemeColor.B0.color.withAlphaComponent(0.0).cgColor],
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
        
        
        self.collectionView.allowsMultipleSelection = true
        
        self.view.addSubview(self.bottomGradientView)
        self.view.addSubview(self.button)
        
        self.$selectedEmotions.mainSink { [unowned self] items in
            self.updateButton()
        }.store(in: &self.cancellables)
        
        self.dataSource.didSelectEmotion = { [unowned self] emotion in
            self.handleSelected(emotion: emotion)
        }
        
        self.dataSource.didSelectRemove = { [unowned self] in
            self.removeLastEmotion()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        
        if self.showButton {
            self.button.pinToSafeAreaBottom()
        } else {
            self.button.top = self.view.height
        }
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    private func removeLastEmotion() {
        self.selectedEmotions.removeFirst()
        self.updateItems()
    }
    
    private func handleSelected(emotion: Emotion) {
        if self.selectedEmotions.contains(emotion) {
            self.selectedEmotions.remove(object: emotion)
        } else {
            self.selectedEmotions.insert(emotion, at: 0)
        }
        
        self.updateItems()
    }
    
    /// The currently running task that is loading conversations.
    private var loadTask: Task<Void, Never>?
    
    private func updateItems() {
        self.loadTask?.cancel()
        
        self.loadTask = Task { [weak self] in
            guard let `self` = self else { return }
            
            var snapshot = self.dataSource.snapshot()
            
            var contentItems: [EmotionsCollectionViewDataSource.ItemType] = self.selectedEmotions.compactMap({ emotion in
                return .emotion(EmotionContentModel(emotion: emotion))
            })
            
            if contentItems.isEmpty {
                contentItems = [.emotion(EmotionContentModel(emotion: nil))]
            }
            
            snapshot.setItems(contentItems, in: .content)
            
            let categoryItems: [EmotionsCollectionViewDataSource.ItemType] = EmotionCategory.allCases.compactMap { category in
                let model = EmotionCategoryModel(category: category, selectedEmotions: self.selectedEmotions)
                return .category(model)
            }
            
            snapshot.setItems(categoryItems, in: .categories)
            
            await self.dataSource.apply(snapshot)
        }
    }
    
    private func updateButton() {
        self.button.set(style: .custom(color: .white, textColor: .B0, text: "Done"))
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.showButton = self.selectedEmotions.count > 0
            self.view.layoutNow()
        }
    }
    
    override func getAllSections() -> [EmotionsCollectionViewDataSource.SectionType] {
        return EmotionsCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] {
        var data: [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] = [:]
        
        data[.content] = [.emotion(EmotionContentModel(emotion: nil))]
        
        data[.categories] = EmotionCategory.allCases.compactMap({ category in
            return .category(EmotionCategoryModel(category: category, selectedEmotions: []))
        })
        return data
    }
}
