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
        case emotions
    }

    struct ItemType: Hashable {
        let emotion: Emotion
    }

    private let emotionCellRegistration = ManageableCellRegistration<EmotionContentCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch section {
        case .emotions:
            return collectionView.dequeueConfiguredReusableCell(using: self.emotionCellRegistration,
                                                                for: indexPath,
                                                                item: EmotionContentModel(emotion: item.emotion))
        }
    }
}
