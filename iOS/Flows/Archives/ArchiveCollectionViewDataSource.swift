//
//  ArchiveCollectionDataSource.swift
//  ArchiveCollectionDataSource
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveCollectionViewDataSource: CollectionViewDataSource<ArchiveCollectionViewDataSource.SectionType,
                                       ArchiveCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case conversations
    }

    enum ItemType: Hashable {
        case conversation(DisplayableConversation)
    }

    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .conversation(let conversation):
            return collectionView.dequeueConfiguredReusableCell(using: self.conversationConfig,
                                                                for: indexPath,
                                                                item: conversation)
        }
    }
}
