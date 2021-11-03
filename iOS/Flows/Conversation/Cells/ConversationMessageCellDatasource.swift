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
                                                                      self))


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

    // MARK: - Helper Functions
    
    func getStackIndex(forIndexPath indexPath: IndexPath) -> Int {
        guard let sectionID = self.sectionIdentifier(for: indexPath.section) else { return 0 }

        let totalCellsInSection = self.itemIdentifiers(in: sectionID).count

        // The higher the cell's index, the closer it is to the front of the message stack.
        return totalCellsInSection - indexPath.item - 1
    }
}

// MARK: - Cell registration

extension ConversationMessageCellDataSource {

    typealias MessageSubcellRegistration
    = UICollectionView.CellRegistration<MessageSubcell,
                                            (channelID: ChannelId,
                                             messageID: MessageId,
                                             dataSource: ConversationMessageCellDataSource)>

    static func createMessageSubcellRegistration() -> MessageSubcellRegistration {

        return MessageSubcellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            let dataSource = item.dataSource
            // The higher the cells index, the closer it is to the front of the message stack.
            let stackIndex = dataSource.getStackIndex(forIndexPath: indexPath)

            let showBubbleTail: Bool
            if message.isFromCurrentUser {
                // Only show a speech bubble tail for the front-most user reply.
                showBubbleTail = stackIndex == 0
            } else {
                // Only show a speech bubble tail for the back-most reply from other users.
                showBubbleTail = indexPath.item == 0
            }

            cell.setText(with: message)
            cell.configureBackground(withStackIndex: stackIndex,
                                     message: message,
                                     showBubbleTail: showBubbleTail)

            // The menu interaction should only be on the front most cell,
            // and only if the user created the original message.
            cell.backgroundColorView.interactions.removeAll()
            #warning("")
//            if stackIndex == 0 {
//                let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
//                cell.backgroundColorView.addInteraction(contextMenuInteraction)
//            }
        }
    }
}
