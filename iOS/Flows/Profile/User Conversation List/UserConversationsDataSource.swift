//
//  UserConversationsDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserConversationsDataSource: CollectionViewDataSource<UserConversationsDataSource.SectionType, UserConversationsDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case conversations
    }
    
    enum ItemType: Hashable {
        case conversation(ConversationId)
        case unreadMessages(ConversationId)
    }
    
    let config = ManageableCellRegistration<ConversationCell>().provider
    let unreadConfig = ManageableCellRegistration<UnreadMessagesCell>().provider
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: SectionType, item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .conversation(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: cid)
        case .unreadMessages(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: cid)
        }
    }
}
