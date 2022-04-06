//
//  EmotionCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/27/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmotionsCollectionViewDataSource: CollectionViewDataSource<EmotionCategory,
                                        EmotionsCollectionViewDataSource.ItemType> {

    enum ItemType: Hashable {
        case emotion(Emotion)
    }

    private let config = ManageableCellRegistration<EmotionCell>().provider
    private let contentConfig = ManageableCellRegistration<EmotionContentCell>().provider
    private let headerConfig = ManageableHeaderRegistration<RoomSectionDividerView>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: EmotionCategory,
                              item: ItemType) -> UICollectionViewCell? {

        guard case ItemType.emotion(let emotion) = item else { return nil }
        
        return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                            for: indexPath,
                                                            item: emotion)
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: EmotionCategory,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.leftLabel.setText(section.title)
//                header.button.didSelect { [unowned self] in
//                    self.didSelectAddPerson?()
//                }
            return header
        } else {
            return nil
        }
    }
}
