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
        case unreadMessages(UnreadMessagesModel)
        case empty
    }
    
    let config = ManageableCellRegistration<ConversationCell>().provider
    let unreadConfig = ManageableCellRegistration<UnreadMessagesCell>().provider
    let emptyConfig = ManageableCellRegistration<EmptyUnreadMessagesCell>().provider
    
    weak var messageContentDelegate: MessageContentDelegate?
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: SectionType, item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .conversation(let cid):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                    for: indexPath,
                                                                    item: cid)
            cell.messageContent.delegate = self.messageContentDelegate
            return cell
        case .unreadMessages(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.unreadConfig,
                                                                    for: indexPath,
                                                                    item: model)
            cell.messageContent.delegate = self.messageContentDelegate
            return cell
        case .empty:
            return collectionView.dequeueConfiguredReusableCell(using: self.emptyConfig,
                                                                for: indexPath,
                                                                item: item)
        }
    }
}
