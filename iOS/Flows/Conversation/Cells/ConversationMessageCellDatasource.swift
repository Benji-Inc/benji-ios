//
//  ConversationMessageCellDatasource.swift
//  Jibber
//
//  Created by Martin Young on 11/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationMessageSection = ConversationMessageCellDataSource.SectionType
typealias ConversationMessageItem = ConversationMessageCellDataSource.ItemType

class ConversationMessageCellDataSource: CollectionViewDataSource<ConversationMessageSection,
                                            ConversationMessageItem> {

    enum SectionType: Int, Hashable, CaseIterable {
        case otherMessages = 0
        case currentUserMessages = 1
    }

    struct ItemType: Hashable {
        let channelID: ChannelId
        let messageID: MessageId
    }

    /// A delegate to handle context menu interactions on the subcells.
    var contextMenuDelegate: UIContextMenuInteractionDelegate?

    // Cell registration
    private let messageSubcellRegistration
    = ConversationMessageCellDataSource.createMessageSubcellRegistration()
    private let headerRegistration
    = UICollectionView.SupplementaryRegistration<TimeSentView>(elementKind: UICollectionView.elementKindSectionHeader)
    { supplementaryView, elementKind, indexPath in }
    private let footerRegistration
    = UICollectionView.SupplementaryRegistration<TimeSentView>(elementKind: UICollectionView.elementKindSectionFooter)
    { supplementaryView, elementKind, indexPath in }

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

                let messageCell
                = collectionView.dequeueConfiguredReusableCell(using: self.messageSubcellRegistration,
                                                               for: indexPath,
                                                               item: (item.channelID,
                                                                      item.messageID,
                                                                      collectionView,
                                                                      self.contextMenuDelegate))


                return messageCell
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: ConversationMessageSection,
                                           indexPath: IndexPath) -> UICollectionReusableView? {

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header
            = collectionView.dequeueConfiguredReusableSupplementary(using: self.headerRegistration,
                                                                    for: indexPath)
            if let item = self.itemIdentifiers(in: .otherMessages).last {
                let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                            messageId: item.messageID)
                header.configure(with: messageController.message)
            }

            return header
        case UICollectionView.elementKindSectionFooter:
            let footer
            = collectionView.dequeueConfiguredReusableSupplementary(using: self.footerRegistration,
                                                                    for: indexPath)
            if let item = self.itemIdentifiers(in: .currentUserMessages).last {
                let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                            messageId: item.messageID)
                footer.configure(with: messageController.message)
            }
            return footer
        default:
            return UICollectionReusableView()
        }
    }
}

// MARK: - Cell registration

extension ConversationMessageCellDataSource {

    typealias MessageSubcellRegistration
    = UICollectionView.CellRegistration<MessageSubcell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         collectionView: UICollectionView,
                                         contextMenuDelegate: UIContextMenuInteractionDelegate?)>

    static func createMessageSubcellRegistration() -> MessageSubcellRegistration {

        return MessageSubcellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            cell.setText(with: message)

            var zIndex = 0
            if let layout = item.collectionView.collectionViewLayout as? ConversationMessageCellLayout {
                zIndex = layout.getZIndex(forIndexPath: indexPath)
            }

            // The menu interaction should only be on the front most cell.
            cell.backgroundColorView.interactions.removeAll()
            if zIndex == 0 {
                cell.setContextMenuInteraction(with: item.contextMenuDelegate)
            } else {
                cell.setContextMenuInteraction(with: nil)
            }
        }
    }
}
