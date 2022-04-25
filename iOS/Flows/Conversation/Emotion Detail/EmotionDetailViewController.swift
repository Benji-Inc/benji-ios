//
//  EmotionDetailViewController.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionDetailViewController: DiffableCollectionViewController<EmotionDetailSection,
                                   EmotionDetailItem,
                                   EmotionDetailCollectionViewDataSource> {

    var emotions: [Emotion]

    init(emotions: [Emotion], startingEmotion: Emotion?) {
        var sortedEmotions = emotions
        // Put the starting emotion at the front
        if let startingEmotion = startingEmotion {
            sortedEmotions.remove(object: startingEmotion)
            sortedEmotions.insert(startingEmotion, at: 0)
        }
        self.emotions = sortedEmotions

        let collectionView = CollectionView(layout: EmotionDetailCollectionViewLayout())
        super.init(with: collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadInitialData()
    }

    override func getAllSections() -> [EmotionDetailCollectionViewDataSource.SectionType] {
        return EmotionDetailCollectionViewDataSource.SectionType.allCases
    }

    override func retrieveDataForSnapshot() async
    -> [EmotionDetailCollectionViewDataSource.SectionType : [EmotionDetailCollectionViewDataSource.ItemType]] {

        let emotionsItems = self.emotions.map { emotion in
            return EmotionDetailItem(emotion: emotion)
        }
        var data: [EmotionDetailSection : [EmotionDetailItem]] = [:]
        data[.emotions] = emotionsItems

        return data
    }
}
