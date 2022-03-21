//
//  MembersCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationDetailSectionType = ConversationDetailCollectionViewDataSource.SectionType
typealias ConversationDetailItemType = ConversationDetailCollectionViewDataSource.ItemType

class ConversationDetailCollectionViewDataSource: CollectionViewDataSource<ConversationDetailCollectionViewDataSource.SectionType, ConversationDetailCollectionViewDataSource.ItemType> {
    
    // Show people
    // Add people
    
    // Conversation Info -> who created, when, topic
    
    // Leave conversation
    // Hide conversation (show toggle)
    // Delete conversation


    enum SectionType: Int, CaseIterable {
        case people
        case info
        case options
    }

    enum ItemType: Hashable {
        case member(Member)
        case add(ChannelId)
        case info(ChannelId)
        case leave(ChannelId)
        case hide(ChannelId)
        case delete(ChannelId)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
    private let addConfig = ManageableCellRegistration<MemberAddCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .member(let member):
            return collectionView.dequeueConfiguredReusableCell(using: self.memberConfig,
                                                                for: indexPath,
                                                                item: member)
        case .add(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.addConfig,
                                                                for: indexPath,
                                                                item: cid)
        case .info(let cid):
            return nil
        case .leave(let cid):
            return nil
        case .hide(let cid):
            return nil
        case .delete(let cid):
            return nil 
        }
    }
}
