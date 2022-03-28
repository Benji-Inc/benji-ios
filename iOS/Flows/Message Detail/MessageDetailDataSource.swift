//
//  MessageDetailDataSource.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/28/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MessageDetailDataSource: CollectionViewDataSource<ConversationDetailCollectionViewDataSource.SectionType, ConversationDetailCollectionViewDataSource.ItemType> {

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
            return nil
//            switch self {
//            case .add:
//                return UIImage(systemName: "person.badge.plus")
//            case .hide:
//                return UIImage(systemName: "eye.slash")
//            case .leave:
//                return UIImage(systemName: "hand.wave")
//            case .delete:
//                return UIImage(systemName: "trash")
//            }
        }
        
        var title: String {
            return ""
//            switch self {
//            case .add:
//                return "Add People"
//            case .hide:
//                return "Hide Conversation"
//            case .leave:
//                return "Leave Conversation"
//            case .delete:
//                return "Delete Conversation"
//            }
        }
        
        var color: ThemeColor {
            return .red
//            switch self {
//            case .add:
//                return .T1
//            case .hide:
//                return .T1
//            case .leave:
//                return .T1
//            case .delete:
//                return .red
//            }
        }
    }

    enum ItemType: Hashable {
        case members([Member])
        case info(MessageId)
        case reply(MessageId)
    }

//    private let memberConfig = ManageableCellRegistration<MemberCell>().provider
//    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
//    private let detailConfig = ManageableCellRegistration<ConversationDetailCell>().provider
//    private let infoConfig = ManageableCellRegistration<ConversationInfoCell>().provider
//    private let editConfig = ManageableCellRegistration<ConversationEditCell>().provider

    // MARK: - Cell Dequeueing

//    override func dequeueCell(with collectionView: UICollectionView,
//                              indexPath: IndexPath,
//                              section: SectionType,
//                              item: ItemType) -> UICollectionViewCell? {
//        return nil
////        let lastIndex = self.snapshot().numberOfItems(inSection: section) - 1
////        let shouldHideLine = lastIndex == indexPath.row
////
////        switch item {
////        case .info(let cid):
////            let cell = collectionView.dequeueConfiguredReusableCell(using: self.infoConfig,
////                                                                    for: indexPath,
////                                                                    item: cid)
////            return cell
////        case .editTopic(let cid):
////            let cell = collectionView.dequeueConfiguredReusableCell(using: self.editConfig,
////                                                                    for: indexPath,
////                                                                    item: cid)
////            return cell
////        case .member(let member):
////            let cell = collectionView.dequeueConfiguredReusableCell(using: self.memberConfig,
////                                                                    for: indexPath,
////                                                                    item: member)
////            cell.lineView.isHidden = shouldHideLine
////            return cell
////        case .detail(let type):
////            let cell = collectionView.dequeueConfiguredReusableCell(using: self.detailConfig,
////                                                                    for: indexPath,
////                                                                    item: type)
////
////            cell.lineView.isHidden = shouldHideLine
////            return cell
////        }
//    }
    
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
