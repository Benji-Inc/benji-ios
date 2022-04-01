//
//  CircleCollectionViewDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation


typealias RoomSectionType = RoomCollectionViewDataSource.SectionType
typealias RoomItemType = RoomCollectionViewDataSource.ItemType

class RoomCollectionViewDataSource: CollectionViewDataSource<RoomSectionType, RoomItemType> {

    enum SectionType: Int, CaseIterable {
        case notices
        case members
        case conversations
    }

    enum ItemType: Hashable {
        case notice(Notice)
        case memberId(String)
        case conversation(ConversationId)
        case add([String])
    }

    private let config = ManageableCellRegistration<RoomMemberCell>().provider
    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider
    private let headerConfig = ManageableHeaderRegistration<RoomSegmentControlHeaderView>().provider
    private let addConfig = ManageableCellRegistration<RoomAddCell>().provider
    private let memberHeaderConfig = ManageableHeaderRegistration<SectionHeaderView>().provider
    
    var didSelectSegmentIndex: ((ConversationsSegmentControl.SegmentType) -> Void)? = nil

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .notice(let notice):
            return nil 
        case .memberId(let member):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: member)
        case .conversation(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.conversationConfig,
                                                                for: indexPath,
                                                                item: cid)
        case .add(let reservationIds):
            return collectionView.dequeueConfiguredReusableCell(using: self.addConfig,
                                                                for: indexPath,
                                                                item: reservationIds)
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .members:
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.memberHeaderConfig, for: indexPath)
            header.leftLabel.setText("Favorites")
            header.rightLabel.setText("")
            header.lineView.isHidden = true
            return header
        case .conversations:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.segmentControl.didSelectSegmentIndex = { [unowned self] index in
                self.didSelectSegmentIndex?(index)
            }
            return header
        default:
            return nil
        }
    }
}
