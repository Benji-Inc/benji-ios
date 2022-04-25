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
    let startingEmotion: Emotion?


    init(emotions: [Emotion], startingEmotion: Emotion?) {
        self.emotions = emotions
        self.startingEmotion = startingEmotion

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

    override func getAnimationCycle(with snapshot: NSDiffableDataSourceSnapshot<EmotionDetailSection, EmotionDetailItem>)
    -> AnimationCycle? {

        var scrollToIndexPath: IndexPath? = nil
        if let startingEmotion = self.startingEmotion,
           let index = snapshot.indexOfItem(EmotionDetailItem(emotion: startingEmotion)) {

            scrollToIndexPath = IndexPath(item: index, section: 0)
        }

        return AnimationCycle(inFromPosition: .inward,
                              outToPosition: .inward,
                              shouldConcatenate: false,
                              scrollToIndexPath: scrollToIndexPath)
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
