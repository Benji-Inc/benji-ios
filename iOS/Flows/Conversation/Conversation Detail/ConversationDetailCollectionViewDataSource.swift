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
        case pins
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
                return ImageSymbol.personBadgePlus.image
            case .hide:
                return ImageSymbol.eyeSlash.image
            case .leave:
                return ImageSymbol.handWave.image
            case .delete:
                return ImageSymbol.trash.image
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
                return .white
            case .hide:
                return .white
            case .leave:
                return .white
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
        case pinnedMessage(PinModel)
    }

    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
    private let detailConfig = ManageableCellRegistration<ConversationDetailCell>().provider
    private let infoConfig = ManageableCellRegistration<ConversationInfoCell>().provider
    private let editConfig = ManageableCellRegistration<ConversationEditCell>().provider
    private let pinConfig = ManageableCellRegistration<PinnedMessageCell>().provider
    private let headerConfig = ManageableHeaderRegistration<SectionDividerView>().provider
    
    weak var messageContentDelegate: MessageContentDelegate?

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
        case .pinnedMessage(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.pinConfig,
                                                                    for: indexPath,
                                                                    item: model)
            cell.content.delegate = self.messageContentDelegate
            return cell
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch section {
        case .pins:
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
                header.leftLabel.setText("Pinned Messages")
                header.imageView.isVisible = false
                return header
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
