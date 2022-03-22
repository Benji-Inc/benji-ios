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
    
    enum OptionType: Int {
        case info
        case hide
        case leave
        case delete
    }

    enum ItemType: Hashable {
        case member(Member)
        case add(ChannelId)
        case detail(ChannelId, OptionType)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
    private let addConfig = ManageableCellRegistration<MemberAddCell>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
    private let detailConfig = ManageableCellRegistration<ConversationDetailCell>().provider

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
        case .detail(let cid, let type):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.detailConfig,
                                                                    for: indexPath,
                                                                    item: cid)
            switch type {
            case .info:
                return nil
            case .hide:
                cell.imageView.image = UIImage(systemName: "hand.wave")
                cell.label.setText("Leave Conversation")
                cell.rightImageView.image = nil
            case .leave:
                cell.imageView.image = UIImage(systemName: "eye.slash")
                cell.label.setText("Hide Conversation")
                cell.rightImageView.image = nil
                return cell
            case .delete:
                cell.imageView.image = UIImage(systemName: "trash")
                cell.imageView.tintColor = ThemeColor.red.color
                cell.label.setTextColor(.red)
                cell.label.setText("Delete Conversation")
                cell.rightImageView.image = nil
                cell.lineView.isHidden = true 
            }
            
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
