//
//  EmotionDetailCollectionViewDataSource.swift
//  Jibber
//
//  Created by Martin Young on 4/25/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias EmotionDetailSection = EmotionDetailCollectionViewDataSource.SectionType
typealias EmotionDetailItem = EmotionDetailCollectionViewDataSource.ItemType

class EmotionDetailCollectionViewDataSource: CollectionViewDataSource<EmotionDetailSection,
                                             EmotionDetailItem> {

    enum SectionType: Int, Hashable, CaseIterable {
        case info
    }
    
    enum ItemType: Hashable {
        case emotion(Emotion)
        case expression(Expression)
    }

    private let emotionCellRegistration = ManageableCellRegistration<EmotionContentCell>().provider
    private let expressionCellRegistration = ManageableCellRegistration<ExpressionCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .expression(let expression):
            return collectionView.dequeueConfiguredReusableCell(using: self.expressionCellRegistration,
                                                                for: indexPath,
                                                                item: expression)
        case .emotion(let emotion):
            return collectionView.dequeueConfiguredReusableCell(using: self.emotionCellRegistration,
                                                                for: indexPath,
                                                                item: EmotionContentModel(emotion: emotion))
        }
    }
}
