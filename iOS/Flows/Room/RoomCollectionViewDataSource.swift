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
        case notice(SystemNotice)
        case memberId(String)
        case conversation(ConversationId)
        case unreadMessages(UnreadMessagesModel)
        case add(String)
        case empty
    }
    
    private let config = ManageableCellRegistration<RoomMemberCell>().provider
    private let conversationConfig = ManageableCellRegistration<ConversationCell>().provider
    private let unreadConfig = ManageableCellRegistration<UnreadMessagesCell>().provider
    private let emptyConfig = ManageableCellRegistration<EmptyUnreadMessagesCell>().provider
    private let headerConfig = ManageableHeaderRegistration<RoomSegmentControlHeaderView>().provider
    private let addConfig = ManageableCellRegistration<RoomAddCell>().provider
    private let memberHeaderConfig = ManageableHeaderRegistration<RoomSectionDividerView>().provider
    private let memberFooterConfig = ManageableFooterRegistration<RoomSectionDividerView>().provider
    private let noticeCell = ManageableCellRegistration<NoticeCell>().provider
    
    var didSelectSegmentIndex: ((ConversationsSegmentControl.SegmentType) -> Void)? = nil
    var didSelectAddPerson: CompletionOptional = nil
    var didSelectAddConversation: CompletionOptional = nil
    
    var didSelectRightOption: ((SystemNotice) -> Void)? = nil
    var didSelectLeftOption: ((SystemNotice) -> Void)? = nil
    
    // MARK: - Cell Dequeueing
    
    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        switch item {
        case .notice(let notice):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.noticeCell,
                                                                    for: indexPath,
                                                                    item: notice)
            cell.didTapLeftButton = { [unowned self] in
                self.didSelectLeftOption?(notice)
            }
            cell.didTapRightButton = { [unowned self] in
                self.didSelectRightOption?(notice)
            }
            return cell
        case .memberId(let member):
            return collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                for: indexPath,
                                                                item: member)
        case .conversation(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.conversationConfig,
                                                                for: indexPath,
                                                                item: cid)
        case .unreadMessages(let cid):
            return collectionView.dequeueConfiguredReusableCell(using: self.unreadConfig,
                                                                for: indexPath,
                                                                item: cid)
        case .add(let reservationId):
            return collectionView.dequeueConfiguredReusableCell(using: self.addConfig,
                                                                for: indexPath,
                                                                item: reservationId)
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
        case .members:
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.memberHeaderConfig, for: indexPath)
                header.leftLabel.setText("Favorites")
                header.button.didSelect { [unowned self] in
                    self.didSelectAddPerson?()
                }
                return header
            } else if kind == UICollectionView.elementKindSectionFooter {
                let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.memberFooterConfig, for: indexPath)
                footer.leftLabel.setText("Conversations")
                footer.button.didSelect { [unowned self] in
                    self.didSelectAddConversation?()
                }
                return footer
            } else {
                return nil
            }
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
