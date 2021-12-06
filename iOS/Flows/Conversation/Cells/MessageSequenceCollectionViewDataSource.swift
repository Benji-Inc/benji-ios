//
//  ConversationMessageCellDatasource.swift
//  Jibber
//
//  Created by Martin Young on 11/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias MessageSequenceSection = MessageSequenceCollectionViewDataSource.SectionType
typealias MessageSequenceItem = MessageSequenceCollectionViewDataSource.ItemType

class MessageSequenceCollectionViewDataSource: CollectionViewDataSource<MessageSequenceSection,
                                               MessageSequenceItem> {

    enum SectionType: Int, Hashable, CaseIterable {
        case topMessages = 0
        case bottomMessages = 1
    }

    struct ItemType: Hashable {
        let channelID: ChannelId
        let messageID: MessageId
    }

    var handleTappedMessage: ((MessageSequenceItem, MessageContentView) -> Void)?
    var handleEditMessage: ((MessageSequenceItem) -> Void)?

    /// If true, push the bottom messages back to prepare for a new message.
    var prepareForSend = false

    // Cell registration
    private let messageSubcellRegistration
    = MessageSequenceCollectionViewDataSource.createMessageSubcellRegistration()

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

    /// Updates the datasource to display the given message sequence.
    /// The message sequence should be ordered newest to oldest.
    func set(messageSequence: MessageSequence) {
        // Separate the user messages from other message.
        let userMessages = messageSequence.messages.filter { message in
            return message.isFromCurrentUser
        }

        let otherMessages = messageSequence.messages.filter { message in
            return !message.isFromCurrentUser
        }

        let cid = try! ChannelId(cid: messageSequence.conversationId)
        // The newest message is at the bottom, so reverse the order.
        var userMessageItems = userMessages.reversed().map { message in
            return MessageSequenceItem(channelID: cid, messageID: message.id)
        }
        if self.prepareForSend {
            userMessageItems.append(MessageSequenceItem(channelID: cid, messageID: "placeholderMessage"))
        }

        let otherMessageItems = otherMessages.reversed().map { message in
            return MessageSequenceItem(channelID: try! ChannelId(cid: message.conversationId),
                                       messageID: message.id)
        }

        var snapshot = self.snapshot()

        var animateDifference = true
        if snapshot.numberOfItems == 0 {
            animateDifference = false
        }

        // Clear out the sections to make way for a fresh set of messages.
        snapshot.deleteSections(MessageSequenceSection.allCases)
        snapshot.appendSections(MessageSequenceSection.allCases)

        snapshot.appendItems(otherMessageItems, toSection: .topMessages)
        snapshot.appendItems(userMessageItems, toSection: .bottomMessages)

        self.apply(snapshot, animatingDifferences: animateDifference)
    }
}

// MARK: - Cell registration

extension MessageSequenceCollectionViewDataSource {

    typealias MessageSubcellRegistration
    = UICollectionView.CellRegistration<MessageSubcell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         collectionView: UICollectionView)>

    static func createMessageSubcellRegistration() -> MessageSubcellRegistration {
        return MessageSubcellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else {
                return
            }

            cell.configure(with: message, showAuthor: false)
        }
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension MessageSequenceCollectionViewDataSource: TimeMachineCollectionViewLayoutDataSource {

    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItem? {
        guard let item = self.itemIdentifier(for: indexPath) else { return nil }
        let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                    messageId: item.messageID)

        return messageController.message
    }
}

extension Message: TimeMachineLayoutItem {

    var sortValue: Double {
        return self.createdAt.timeIntervalSinceReferenceDate
    }
}
