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
        case unreadMessages(UnreadMessagesModel)
        case empty
    }
    
    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider
    private let unreadConfig = ManageableCellRegistration<UnreadMessagesCell>().provider
    private let emptyConfig = ManageableCellRegistration<EmptyUnreadMessagesCell>().provider
    private let headerConfig = ManageableHeaderRegistration<RoomSegmentControlHeaderView>().provider
    
    var didSelectSegmentIndex: ((ConversationsSegmentControl.SegmentType) -> Void)? = nil
    
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
        case .unreadMessages(let cid):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.unreadConfig,
                                                                    for: indexPath,
                                                                    item: cid)
            cell.content.messageContent.delegate = self.messageContentDelegate
            cell.content.lineView.isHidden = self.snapshot().numberOfItems(inSection: section) - 1 == indexPath.row
            return cell
        case .empty:
            return collectionView.dequeueConfiguredReusableCell(using: self.emptyConfig,
                                                                for: indexPath,
                                                                item: .empty)
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .conversations:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.segmentControl.didSelectSegmentIndex = { [unowned self] index in
                self.didSelectSegmentIndex?(index)
            }
            return header
        }
    }
}
