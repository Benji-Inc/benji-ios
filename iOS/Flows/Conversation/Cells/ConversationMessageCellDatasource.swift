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

    var handleTappedMessage: ((ConversationMessageItem, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationMessageItem) -> Void)?

    // Cell registration
    private let messageSubcellRegistration
    = ConversationMessageCellDataSource.createMessageSubcellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        let messageCell
        = collectionView.dequeueConfiguredReusableCell(using: self.messageSubcellRegistration,
                                                       for: indexPath,
                                                       item: (item.channelID,
                                                              item.messageID,
                                                              collectionView))
        messageCell.content.handleEditMessage = { [unowned self] item in
            self.handleEditMessage?(item)
        }

        messageCell.content.handleTappedMessage = { [unowned self] item in
            self.handleTappedMessage?(item, messageCell.content)
        }
        return messageCell
    }
}

// MARK: - Cell registration

extension ConversationMessageCellDataSource {

    typealias MessageSubcellRegistration
    = UICollectionView.CellRegistration<MessageSubcell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         collectionView: UICollectionView)>

    static func createMessageSubcellRegistration() -> MessageSubcellRegistration {

        return MessageSubcellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }

            cell.configure(with: message)

            var zIndex = 0
            if let layout = item.collectionView.collectionViewLayout as? ConversationMessagesCellLayout {
                zIndex = layout.getZIndex(forIndexPath: indexPath)
            }

            // The menu interaction should only be on the front most cell.
            cell.content.backgroundColorView.interactions.removeAll()
            if zIndex == 0 {
                cell.content.setContextMenu()
            } else {
                cell.content.backgroundColorView.interactions.removeAll()
            }
        }
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension ConversationMessageCellDataSource: TimeMachineCollectionViewLayoutDataSource {

    func getConversation(at indexPath: IndexPath) -> Conversation? {
        guard let item = self.itemIdentifier(for: indexPath) else { return nil }

        return ChatClient.shared.channelController(for: item.channelID).conversation
    }

    func getMessage(at indexPath: IndexPath) -> Messageable? {
        guard let item = self.itemIdentifier(for: indexPath) else { return nil }
        let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                    messageId: item.messageID)

        return messageController.message
    }

    func frontMostItemWasUpdated(for indexPath: IndexPath) {
        logDebug("\(indexPath.description)")
    }
}
