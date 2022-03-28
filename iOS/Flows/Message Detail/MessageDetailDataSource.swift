//
//  MessageDetailDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MessageDetailDataSource: CollectionViewDataSource<MessageDetailDataSource.SectionType, MessageDetailDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case options
        case reads
        case recentReply
        case metadata
    }
    
    enum OptionType: Int, OptionDisplayable {
        
        case viewReplies
        case edit
        case pin
        case more
        case delete
        
        var image: UIImage? {
            switch self {
            case .viewReplies:
                return UIImage(systemName: "arrowshape.turn.up.left")
            case .edit:
                return UIImage(systemName: "pencil")
            case .pin:
                return UIImage(systemName: "bookmark")
            case .more:
                return UIImage(systemName: "ellipsis")
            case .delete:
                return UIImage(systemName: "trash")
            }
        }
        
        var title: String {
            switch self {
            case .viewReplies:
                return "Reply"
            case .edit:
                return "Edit"
            case .pin:
                return "Pin"
            case .more:
                return "More"
            case .delete:
                return "Delete Message"
            }
        }
        
        var color: ThemeColor {
            switch self {
            case .delete:
                return .red
            default:
                return .T1
            }
        }
    }

    enum ItemType: Hashable {
        case option(OptionType)
        case members([Member])
        case info(MessageId)
        case reply(MessageId)
    }
    
    private let topOptionConfig = ManageableCellRegistration<MessageTopOptionCell>().provider

//    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
//    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
//    private let detailConfig = ManageableCellRegistration<ConversationDetailCell>().provider
//    private let infoConfig = ManageableCellRegistration<ConversationInfoCell>().provider
//    private let editConfig = ManageableCellRegistration<ConversationEditCell>().provider

    // MARK: - Cell Dequeueing

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {
        
        switch item {
        case .option(let option):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.topOptionConfig,
                                                                    for: indexPath,
                                                                    item: option)
            return cell
        case .members(_):
            return nil
        case .info(_):
            return nil
        case .reply(_):
            return nil
        }
//        let lastIndex = self.snapshot().numberOfItems(inSection: section) - 1
//        let shouldHideLine = lastIndex == indexPath.row
//
//        switch item {
//        case .info(let cid):

//        case .editTopic(let cid):
//            let cell = collectionView.dequeueConfiguredReusableCell(using: self.editConfig,
//                                                                    for: indexPath,
//                                                                    item: cid)
//            return cell
//        case .member(let member):
//            let cell = collectionView.dequeueConfiguredReusableCell(using: self.memberConfig,
//                                                                    for: indexPath,
//                                                                    item: member)
//            cell.lineView.isHidden = shouldHideLine
//            return cell
//        case .detail(let type):
//            let cell = collectionView.dequeueConfiguredReusableCell(using: self.detailConfig,
//                                                                    for: indexPath,
//                                                                    item: type)
//
//            cell.lineView.isHidden = shouldHideLine
//            return cell
//        }
    }
    
//    override func dequeueSupplementaryView(with collectionView: UICollectionView, kind: String,
//                                           section: SectionType,
//                                           indexPath: IndexPath) -> UICollectionReusableView? {
//
//        if kind == SectionBackgroundView.kind {
//            return collectionView.dequeueConfiguredReusableSupplementary(using: self.backgroundConfig,
//                                                                         for: indexPath)
//        }
//
//        return nil
//    }
}
