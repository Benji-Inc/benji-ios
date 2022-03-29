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
        case messages
    }

    enum ItemType: Hashable {
        case message(cid: ConversationId,
                     messageID: MessageId,
                     showDetail: Bool = true)
        case loadMore(cid: ConversationId)
        case placeholder
        case initial(cid: ConversationId)
    }

    // Input handling
    weak var messageCellDelegate: MesssageCellDelegate?
    var handleLoadMoreMessages: ((ConversationId) -> Void)?

    /// If true, show the detail bar for each message
    var shouldShowDetailBar = true
    /// If true, push the bottom messages back to prepare for a new message.
    var shouldPrepareToSend = false
    /// If true, set up the messages to accomodate a drop zone being shown.
    var layoutForDropZone: Bool = false

    // Cell registration
    private let messageCellRegistration
    = MessageSequenceCollectionViewDataSource.createMessageCellRegistration()
    private let loadMoreRegistration
    = MessageSequenceCollectionViewDataSource.createLoadMoreCellRegistration()
    private let placeholderRegistration
    = MessageSequenceCollectionViewDataSource.createPlaceholderMessageCellRegistration()
    private let initialCellRegistration
    = MessageSequenceCollectionViewDataSource.createInitialCellRegistration()
    
    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .message(cid: let cid, messageID: let messageID, let showDetail):
            let messageCell
            = collectionView.dequeueConfiguredReusableCell(using: self.messageCellRegistration,
                                                           for: indexPath,
                                                           item: (cid, messageID, showDetail, collectionView))
            messageCell.shouldShowDetailBar = self.shouldShowDetailBar
            messageCell.delegate = self.messageCellDelegate

            return messageCell
        case .loadMore(cid: let conversationID):
            let loadMoreCell = collectionView.dequeueConfiguredReusableCell(using: self.loadMoreRegistration,
                                                                            for: indexPath,
                                                                            item: collectionView)
            loadMoreCell.handleLoadMoreMessages = { [unowned self] in
                self.handleLoadMoreMessages?(conversationID)
            }
            return loadMoreCell
        case .placeholder:
            return collectionView.dequeueConfiguredReusableCell(using: self.placeholderRegistration,
                                                                for: indexPath,
                                                                item: collectionView)
        case .initial(let conversationID):
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.initialCellRegistration,
                                                                            for: indexPath,
                                                                            item: (conversationID, collectionView))
            return cell
        }
    }

    /// Updates the datasource to display the given message sequence.
    /// The message sequence should be ordered newest to oldest.
    func set(messageSequence: MessageSequence,
             itemsToReconfigure: [ItemType] = [],
             showLoadMore: Bool = false) {

        // Don't show deleted messages
        let messages = messageSequence.messages.filter { message in
            return !message.isDeleted
        }

        guard let cid = messageSequence.streamCID else {
            self.deleteAllItems()
            return
        }

        // The newest message is at the bottom, so reverse the order.
        var messageItems = messages.map { message in
            return ItemType.message(cid: cid, messageID: message.id)
        }
        messageItems = messageItems.reversed()

        if self.shouldPrepareToSend {
            messageItems.append(.placeholder)
        }

        if showLoadMore {
            messageItems.insert(.loadMore(cid: cid), at: 0)
        } else {
            messageItems.insert(.initial(cid: cid), at: 0)
        }
        
        var snapshot = self.snapshot()

        var animateDifference = true
        if snapshot.numberOfItems == 0 {
            animateDifference = false
        }

        // Clear out the sections to make way for a fresh set of messages.
        snapshot.deleteSections(MessageSequenceSection.allCases)
        snapshot.appendSections(MessageSequenceSection.allCases)

        snapshot.appendItems(messageItems, toSection: .messages)

        snapshot.reconfigureItems(itemsToReconfigure)

        self.apply(snapshot, animatingDifferences: animateDifference)
    }
}

// MARK: - Cell Registration

extension MessageSequenceCollectionViewDataSource {

    typealias MessageCellRegistration
    = UICollectionView.CellRegistration<MessageCell,
                                        (channelID: ChannelId,
                                         messageID: MessageId,
                                         showDetail: Bool,
                                         collectionView: UICollectionView)>
    typealias LoadMoreCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, UICollectionView?>
    typealias PlaceholderMessageCellRegistration
    = UICollectionView.CellRegistration<PlaceholderMessageCell, UICollectionView?>
    typealias InitialMessageCellRegistration
    = UICollectionView.CellRegistration<InitialMessageCell, (channelID: ChannelId, UICollectionView?)>

    static func createMessageCellRegistration() -> MessageCellRegistration {
        return MessageCellRegistration { cell, indexPath, item in
            let messageController = ChatClient.shared.messageController(cid: item.channelID,
                                                                        messageId: item.messageID)
            guard let message = messageController.message else { return }
            cell.shouldShowDetailBar = item.showDetail
            cell.configure(with: message)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreCellRegistration {
        return LoadMoreCellRegistration { cell, indexPath, item in }
    }

    static func createPlaceholderMessageCellRegistration() -> PlaceholderMessageCellRegistration {
        return PlaceholderMessageCellRegistration { cell, indexPath, itemIdentifier in
            #warning("remove debugging")
//            cell.contentView.backgroundColor = .red
        }
    }
    
    static func createInitialCellRegistration() -> InitialMessageCellRegistration {
        return InitialMessageCellRegistration { cell, indexPath, item in
            let controller = ChatClient.shared.channelController(for: item.channelID)
            cell.configure(with: controller.conversation)
        }
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension MessageSequenceCollectionViewDataSource: TimeMachineCollectionViewLayoutDataSource {

    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItemType {
        guard let item = self.itemIdentifier(for: indexPath) else {
            return TimeMachineLayoutItem(layoutId: String())
        }

        return self.getTimeMachineItem(forItem: item)
    }

    private func getTimeMachineItem(forItem item: ItemType) -> TimeMachineLayoutItemType {
        switch item {
        case .message(_, let messageID, _):
            return TimeMachineLayoutItem(layoutId: messageID)
        case .loadMore:
            return TimeMachineLayoutItem(layoutId: "loadMore")
        case .initial:
            return TimeMachineLayoutItem(layoutId: "initial")
        case .placeholder:
            return TimeMachineLayoutItem(layoutId: "placeholder")
        }
    }
}

private struct TimeMachineLayoutItem: TimeMachineLayoutItemType {
    var layoutId: String
}
