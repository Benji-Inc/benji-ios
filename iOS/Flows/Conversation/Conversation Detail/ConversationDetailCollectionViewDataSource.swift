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
    
    enum OptionType: Int {
        case hide
        case leave
        case delete
    }

    enum ItemType: Hashable {
        case member(Member)
        case add(ChannelId)
        case info(ChannelId)
        case editTopic(ChannelId)
        case detail(ChannelId, OptionType)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
    private let addConfig = ManageableCellRegistration<MemberAddCell>().provider
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
        case .add(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.addConfig,
                                                                for: indexPath,
                                                                item: cid)
        case .detail(let cid, let type):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.detailConfig,
                                                                    for: indexPath,
                                                                    item: cid)
            switch type {
            case .hide:
                cell.imageView.image = UIImage(systemName: "eye.slash")
                cell.label.setText("Hide Conversation")
                cell.rightImageView.image = nil
            case .leave:
                cell.imageView.image = UIImage(systemName: "hand.wave")
                cell.label.setText("Leave Conversation")
                cell.rightImageView.image = nil
                return cell
            case .delete:
                cell.imageView.image = UIImage(systemName: "trash")
                cell.imageView.tintColor = ThemeColor.red.color
                cell.label.setTextColor(.red)
                cell.label.setText("Delete Conversation")
                cell.rightImageView.image = nil
            }
            
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
