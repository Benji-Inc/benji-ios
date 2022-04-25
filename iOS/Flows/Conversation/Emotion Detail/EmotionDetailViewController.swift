//
//  EmotionDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailViewController: DiffableCollectionViewController<EmotionsCollectionViewDataSource.SectionType,
                                   EmotionsCollectionViewDataSource.ItemType,
                                   EmotionsCollectionViewDataSource> {

    init() {
        super.init(with: EmotionsCollectionView())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func initializeViews() {
        super.initializeViews()


    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadInitialData()
    }

    override func getAllSections() -> [EmotionsCollectionViewDataSource.SectionType] {
        return EmotionsCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async
    -> [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] {
        var data: [EmotionsCollectionViewDataSource.SectionType : [EmotionsCollectionViewDataSource.ItemType]] = [:]

        data[.content] = [.emotion(EmotionContentModel(emotion: nil))]

        data[.categories] = EmotionCategory.allCases.compactMap({ category in
            return .category(EmotionCategoryModel(category: category, selectedEmotions: []))
        })
        return data
    }
}
