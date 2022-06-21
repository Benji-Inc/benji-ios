//
//  MemberSelectionDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSelectionDataSource: CollectionViewDataSource<ConversationSelectionDataSource.SectionType,
                                       ConversationSelectionDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case conversations
    }

    enum ItemType: Hashable {
        case conversation(String)
    }

    private let config = ManageableCellRegistration<ConversationSelectionCell>().provider
            
    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .conversation(let conversationId):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: conversationId)
        }
    }
}
