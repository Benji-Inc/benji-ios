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
        case unpin
        case more
        case quote
        
        var image: UIImage? {
            switch self {
            case .viewReplies:
                return UIImage(systemName: "arrowshape.turn.up.left")
            case .edit:
                return UIImage(systemName: "pencil")
            case .pin:
                return UIImage(systemName: "bookmark")
            case .unpin:
                return UIImage(systemName: "bookmark.slash")
            case .more:
                return UIImage(systemName: "ellipsis")
            case .quote:
                return UIImage(systemName: "quote.opening")
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
            case .unpin:
                return "Unpin"
            case .more:
                return "More"
            case .quote:
                return "Quote"
            }
        }
        
        var color: ThemeColor {
            switch self {
            default:
                return .white
            }
        }
    }

    enum ItemType: Hashable {
        case more(MoreOptionModel)
        case option(OptionType)
        case read(ReadViewModel)
        case info(Message)
        case reply(RecentReplyModel)
    }
    
    private let topOptionConfig = ManageableCellRegistration<MessageTopOptionCell>().provider
    private let readConfig = ManageableCellRegistration<MessageReadCell>().provider
    private let headerConfig = ManageableHeaderRegistration<SectionHeaderView>().provider
    private let backgroundConfig = ManageableSupplementaryViewRegistration<SectionBackgroundView>().provider
    private let replyConfig = ManageableCellRegistration<RecentReplyCell>().provider
    private let metadatConfig = ManageableCellRegistration<MessageMetadataCell>().provider
    private let moreConfige = ManageableCellRegistration<MessageMoreCell>().provider
    
    var didTapEdit: CompletionOptional = nil
    var didTapDelete: CompletionOptional = nil

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
        case .read(let read):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.readConfig,
                                                                    for: indexPath,
                                                                    item: read)
            return cell
        case .info(let message):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.metadatConfig,
                                                                    for: indexPath,
                                                                    item: message)
            return cell
        case .reply(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.replyConfig,
                                                                    for: indexPath,
                                                                    item: model)
            return cell
        case .more(let model):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.moreConfige,
                                                                    for: indexPath,
                                                                    item: model)
            cell.didTapEdit = { [unowned self] in
                self.didTapEdit?()
            }
            
            cell.didTapDelete = { [unowned self] in
                self.didTapDelete?()
            }
            
            return cell
        }
    }
    
    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerConfig, for: indexPath)

            switch section {
            case .options:
                break
            case .reads:
                header.leftLabel.setText("Read by")
            case .recentReply:
                header.leftLabel.setText("Latest reply")
            case .metadata:
                header.leftLabel.setText("Metadata")
            }
            
            header.rightLabel.isHidden = true
            header.button.isHidden = true
            header.lineView.isHidden = true 
            return header
        default:
            return nil
        }
    }
}
