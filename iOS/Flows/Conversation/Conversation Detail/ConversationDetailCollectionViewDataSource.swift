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
        case info
        case people
        case options
    }
    
    enum OptionType: Int, OptionDisplayable {
        
        case add
        case hide
        case leave
        case delete
        
        var image: UIImage? {
            switch self {
            case .add:
                return UIImage(systemName: "person.badge.plus")
            case .hide:
                return UIImage(systemName: "eye.slash")
            case .leave:
                return UIImage(systemName: "hand.wave")
            case .delete:
                return UIImage(systemName: "trash")
            }
        }
        
        var title: String {
            switch self {
            case .add:
                return "Add People"
            case .hide:
                return "Hide Conversation"
            case .leave:
                return "Leave Conversation"
            case .delete:
                return "Delete Conversation"
            }
        }
        
        var color: ThemeColor {
            switch self {
            case .add:
                return .T1
            case .hide:
                return .T1
            case .leave:
                return .T1
            case .delete:
                return .red
            }
        }
    }

    enum ItemType: Hashable {
        case member(Member)
        case info(ChannelId)
        case editTopic(ChannelId)
        case detail(OptionType)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
    private let detailConfig = ManageableCellRegistration<ConversationDetailCell>().provider
    private let infoConfig = ManageableCellRegistration<ConversationInfoCell>().provider
    private let editConfig = ManageableCellRegistration<ConversationEditCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        
        let lastIndex = self.snapshot().numberOfItems(inSection: section) - 1
        let shouldHideLine = lastIndex == indexPath.row
        
        switch item {
        case .info(let cid):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.infoConfig,
                                                                    for: indexPath,
                                                                    item: cid)
            return cell
        case .editTopic(let cid):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.editConfig,
                                                                    for: indexPath,
                                                                    item: cid)
            return cell
        case .member(let member):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.memberConfig,
                                                                    for: indexPath,
                                                                    item: member)
            cell.lineView.isHidden = shouldHideLine
            return cell
        case .detail(let type):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.detailConfig,
                                                                    for: indexPath,
                                                                    item: type)
            
            cell.lineView.isHidden = shouldHideLine
            return cell
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        if kind == SectionBackgroundView.kind {
            return collectionView.dequeueConfiguredReusableSupplementary(using: self.backgroundConfig,
                                                                         for: indexPath)
        }
        
        return nil
    }
}
