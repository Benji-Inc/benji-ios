//
//  ProfileDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/22/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ProfileDataSource: CollectionViewDataSource<ProfileDataSource.SectionType, ProfileDataSource.ItemType> {
    
    enum SectionType: Int, CaseIterable {
        case conversations
        case moments
    }
    
    enum ItemType: Hashable {
        case moment(MomentViewModel)
        case conversation(String)
        case unreadMessages(UnreadMessagesModel)
        case empty
    }
    
    let config = ManageableCellRegistration<ConversationCell>().provider
    let unreadConfig = ManageableCellRegistration<UnreadMessagesCell>().provider
    let emptyConfig = ManageableCellRegistration<EmptyUnreadMessagesCell>().provider
    let momentConfig = ManageableCellRegistration<MomentCell>().provider
    
    private let headerConfig = ManageableHeaderRegistration<MomentsHeaderView>().provider
    private let footerConfig = ManageableFooterRegistration<MomentsFooterView>().provider
    
    weak var messageContentDelegate: MessageContentDelegate?
    
    var didSelectViewAll: CompletionOptional = nil 
    
    override func dequeueCell(with collectionView: UICollectionView, indexPath: IndexPath, section: SectionType, item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .moment(let model):
            return collectionView.dequeueConfiguredReusableCell(using: self.momentConfig,
                                                                for: indexPath,
                                                                item: model)
        case .conversation(let conversationId):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.config,
                                                                    for: indexPath,
                                                                    item: conversationId)
            cell.content.messageContent.delegate = self.messageContentDelegate
            return cell
        case .unreadMessages(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.unreadConfig,
                                                                    for: indexPath,
                                                                    item: model)
            cell.content.messageContent.delegate = self.messageContentDelegate
            return cell
        case .empty:
            return collectionView.dequeueConfiguredReusableCell(using: self.emptyConfig,
                                                                for: indexPath,
                                                                item: item)
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
                        
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footer = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerConfig, for: indexPath)
            footer.animate()
            footer.button.didSelect { [unowned self] in
                self.didSelectViewAll?()
            }
            return footer
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)
            header.animate()
            return header
        default:
            return nil 
        }
    }
}
