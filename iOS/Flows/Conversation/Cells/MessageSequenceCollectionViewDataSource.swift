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

    enum ItemType: Hashable {
        case message(cid: ConversationID, messageID: MessageId)
        case loadMore(cid: ConversationID)
    }

    var handleTappedMessage: ((MessageSequenceItem, MessageContentView) -> Void)?
    var handleEditMessage: ((MessageSequenceItem) -> Void)?
    var handleLoadMoreMessages: ((ConversationID) -> Void)?

    /// If true, push the bottom messages back to prepare for a new message.
    var shouldPrepareToSend = false
    /// If true, set up the messages to accomodate a drop zone being shown.
    var layoutForDropZone: Bool = false

    // Cell registration
    private let messageSubcellRegistration
    = MessageSequenceCollectionViewDataSource.createMessageSubcellRegistration()
    private let loadMoreRegistration
    = MessageSequenceCollectionViewDataSource.createLoadMoreCellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .message(cid: let cid, messageID: let messageID):
            let messageCell
            = collectionView.dequeueConfiguredReusableCell(using: self.messageSubcellRegistration,
                                                           for: indexPath,
                                                           item: (cid, messageID, collectionView))
            messageCell.content.handleEditMessage = { [unowned self] item in
                self.handleEditMessage?(item)
            }

            messageCell.content.handleTappedMessage = { [unowned self] item in
                self.handleTappedMessage?(item, messageCell.content)
            }
            return messageCell
        case .loadMore(cid: let conversationID):
            let loadMoreCell = collectionView.dequeueConfiguredReusableCell(using: self.loadMoreRegistration,
                                                                            for: indexPath,
                                                                            item: collectionView)
            loadMoreCell.handleLoadMoreMessages = { [unowned self] in
                self.handleLoadMoreMessages?(conversationID)
            }
            return loadMoreCell
        }
    }

    /// Updates the datasource to display the given message sequence.
    /// The message sequence should be ordered newest to oldest.
    func set(messageSequence: MessageSequence,
             itemsToReconfigure: [ItemType] = [],
             showLoadMore: Bool = false) {
        // Separate the user messages from other message.
        let userMessages = messageSequence.messages.filter { message in
            return message.isFromCurrentUser
        }

        let otherMessages = messageSequence.messages.filter { message in
            return !message.isFromCurrentUser
        }

        guard let cid = messageSequence.streamCID else {
            self.deleteAllItems()
            return
        }

        // The newest message is at the bottom, so reverse the order.
        var userMessageItems = userMessages.map { message in
            return ItemType.message(cid: cid, messageID: message.id)
        }

        if showLoadMore {
            userMessageItems.append(.loadMore(cid: cid))
        }


        userMessageItems = userMessageItems.reversed()
        if self.shouldPrepareToSend {
            userMessageItems.append(ItemType.message(cid: cid, messageID: "placeholderMessage"))
        }

        let otherMessageItems = otherMessages.reversed().map { message in
            return ItemType.message(cid: cid, messageID: message.id)
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

        snapshot.reconfigureItems(itemsToReconfigure)

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

    typealias LoadMoreCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, UICollectionView?>

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

    static func createLoadMoreCellRegistration() -> LoadMoreCellRegistration {
        return LoadMoreCellRegistration { cell, indexPath, item in }
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension MessageSequenceCollectionViewDataSource: TimeMachineCollectionViewLayoutDataSource {

    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItemType {
        guard let item = self.itemIdentifier(for: indexPath) else {
            return TimeMachineLayoutItem(sortValue: .greatestFiniteMagnitude, shouldShow: false)
        }

        return self.getTimeMachineItem(forItem: item)
    }

    private func getTimeMachineItem(forItem item: ItemType) -> TimeMachineLayoutItemType {
        switch item {
        case .message(let channelID, let messageID):
            let messageController = ChatClient.shared.messageController(cid: channelID, messageId: messageID)
            // If the item doesn't correspond to an actual message, then assume it's a placeholder and
            // put it at the front.
            return messageController.message ?? TimeMachineLayoutItem(sortValue: .greatestFiniteMagnitude,
                                                                      shouldShow: false)
        case .loadMore:
            // Get all of the message items.
            let timeMachineItems: [TimeMachineLayoutItemType]
            = self.snapshot().itemIdentifiers.compactMap { itemIdentifier in
                switch itemIdentifier {
                case .message:
                    return self.getTimeMachineItem(forItem: itemIdentifier)
                case .loadMore:
                    return nil
                }
            }

            // Find the oldest message item.
            guard let oldestItem = timeMachineItems.min(by: { (timeMachineItem1, timeMachineItem2) in
                return timeMachineItem1.sortValue < timeMachineItem2.sortValue
            }) else {
                return TimeMachineLayoutItem(sortValue: -.greatestFiniteMagnitude,
                                             shouldShow: true)
            }

            // Put the load more right before the oldest message item.
            return TimeMachineLayoutItem(sortValue: oldestItem.sortValue.nextDown, shouldShow: true)
        }
    }
}

private struct TimeMachineLayoutItem: TimeMachineLayoutItemType {
    var sortValue: Double
    var shouldShow: Bool
}


extension Message: TimeMachineLayoutItemType {
    var sortValue: Double {
        return self.createdAt.timeIntervalSinceReferenceDate
    }

    var shouldShow: Bool {
        return true
    }
}
