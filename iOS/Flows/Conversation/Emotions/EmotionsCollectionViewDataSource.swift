//
//  EmotionCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCollectionViewDataSource: CollectionViewDataSource<EmotionsCollectionViewDataSource.SectionType,
                                        EmotionsCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case emotions
    }

    enum ItemType: Hashable {
        case emotion(Emotion)
    }

    private let config = ManageableCellRegistration<EmotionCell>().provider
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .emotion(let emotion):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: emotion)
        }
    }
}
