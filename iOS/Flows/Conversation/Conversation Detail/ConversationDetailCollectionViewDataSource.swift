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

    enum SectionType: Int, CaseIterable {
        case members
    }

    enum ItemType: Hashable {
        case member(Member)
        case add(ChannelId)
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
        }
    }
}
