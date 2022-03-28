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
            sheet.detents = [.medium()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.prefersGrabberVisible = true 
        }
        
        self.view.set(backgroundColor: .B0)
                        
        self.view.addSubview(self.bottomGradientView)
        
        self.collectionView.allowsMultipleSelection = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInitialData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.bottomGradientView.expandToSuperviewWidth()
        self.bottomGradientView.height = 94
        self.bottomGradientView.pin(.bottom)
    }
    
    override func getAllSections() -> [EmotionsCollectionViewDataSource.SectionType] {
        return EmotionsCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async -> [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] {
        var data: [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] = [:]
        data[.emotions] = Emotion.allCases.compactMap({ emotion in
            return .emotion(emotion)
        })
        return data
    }
}
