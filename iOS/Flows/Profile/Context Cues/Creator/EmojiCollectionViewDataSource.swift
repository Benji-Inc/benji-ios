//
//  EmojiCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class EmojiCollectionViewDataSource: CollectionViewDataSource<EmojiCollectionViewDataSource.SectionType,
                                     EmojiCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case emojis
    }

    enum ItemType: Hashable {
        case emoji(Emoji)
    }

    private let config = ManageableCellRegistration<EmojiCell>().provider
    
    
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .emoji(let emoji):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: emoji)
        }
    }
}
