//
//  EmotionCircleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Martin Young on 4/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias EmotionCircleSection = EmotionCircleCollectionViewDataSource.SectionType
typealias EmotionCircleItem = EmotionCircleCollectionViewDataSource.ItemType

class EmotionCircleCollectionViewDataSource: CollectionViewDataSource<EmotionCircleSection,
                                                EmotionCircleItem> {

    enum SectionType: Int, Hashable {
        case emotions
    }

    struct ItemType: Hashable {
        let emotion: Emotion
    }

    // Cell registration
    private let emotionCellRegistration
    = EmotionCircleCollectionViewDataSource.createEmotionCellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

            let emotionCell
            = collectionView.dequeueConfiguredReusableCell(using: self.emotionCellRegistration,
                                                           for: indexPath,
                                                           item: item)
            return emotionCell
    }
}

// MARK: - Cell Registration

extension EmotionCircleCollectionViewDataSource {

    typealias EmotionCellRegistration
    = UICollectionView.CellRegistration<EmotionCircleCell, EmotionCircleItem>
    
    static func createEmotionCellRegistration() -> EmotionCellRegistration {
        return EmotionCellRegistration { cell, indexPath, item in
            cell.configure(with: item.emotion)
        }
    }
}

// MARK: - EmotionCircleCollectionViewLayoutDataSource

extension EmotionCircleCollectionViewDataSource: EmotionCircleCollectionViewLayoutDataSource {

    func getId(forItemAt indexPath: IndexPath) -> String {
        return self.itemIdentifier(for: indexPath)?.emotion.rawValue ?? String()
    }
}
