//
//  ConversationsCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationsDataSource: CollectionViewDataSource<ConversationsDataSource.SectionType, ConversationsDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case conversations
    }
    
    enum ItemType: Hashable {
        case conversation(String)
    }
    
    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider
        
    weak var messageContentDelegate: MessageContentDelegate?
    
    // MARK: - Cell Dequeueing
    
    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
    
        case .conversation(let conversationId):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.conversationConfig,
                                                                    for: indexPath,
                                                                    item: conversationId)
            cell.content.messageContent.delegate = self.messageContentDelegate
            cell.content.lineView.isHidden = self.snapshot().numberOfItems(inSection: section) - 1 == indexPath.row
            return cell
        }
    }
}
