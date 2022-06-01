//
//  ConversationMessageCellDatasource.swift
//  Jibber
//
//  Created by Martin Young on 11/3/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

typealias MessageSequenceSection = MessageSequenceCollectionViewDataSource.SectionType
typealias MessageSequenceItem = MessageSequenceCollectionViewDataSource.ItemType

class MessageSequenceCollectionViewDataSource: CollectionViewDataSource<MessageSequenceSection,
                                               MessageSequenceItem> {

    enum SectionType: Int, Hashable, CaseIterable {
        case messages
    }

    enum ItemType: Hashable {
        case message(messageId: String,
                     showDetail: Bool = true)
        case loadMore
        case placeholder
        case initial
    }

    /// A conversation controller created for this message sequence
    var messageSequenceController: MessageSequenceController = EmptyMessageSequenceController()

    // Input handling
    weak var messageContentDelegate: MessageContentDelegate?
    var handleLoadMoreMessages: ((String) -> Void)?
    var handleAddMembers: CompletionOptional = nil

    /// If true, show the replies for each message
    var shouldShowReplies: Bool {
        return true 
    }
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
        case .message(messageId: let messageId, let showDetail):
            let messageCell
            = collectionView.dequeueConfiguredReusableCell(using: self.messageCellRegistration,
                                                           for: indexPath,
                                                           item: (self.messageSequenceController,
                                                                  messageId,
                                                                  showDetail,
                                                                  collectionView))

            messageCell.shouldShowReplies = self.shouldShowReplies
            messageCell.shouldShowDetailBar = self.shouldShowDetailBar
            messageCell.content.delegate = self.messageContentDelegate

            return messageCell
        case .loadMore:
            let loadMoreCell = collectionView.dequeueConfiguredReusableCell(using: self.loadMoreRegistration,
                                                                            for: indexPath,
                                                                            item: collectionView)
            if let conversationId = self.messageSequenceController.conversationId {
                loadMoreCell.handleLoadMoreMessages = { [unowned self] in
                    self.handleLoadMoreMessages?(conversationId)
                }
            }
            return loadMoreCell
        case .placeholder:
            return collectionView.dequeueConfiguredReusableCell(using: self.placeholderRegistration,
                                                                for: indexPath,
                                                                item: collectionView)
        case .initial:
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.initialCellRegistration,
                                                                    for: indexPath,
                                                                    item: (self.messageSequenceController,
                                                                           collectionView))
            cell.didTapAddMembers = { [unowned self] in
                self.handleAddMembers?()
            }
            return cell
        }
    }

    /// Updates the datasource to display the given message sequence.
    /// The message sequence should be ordered newest to oldest.
    func set(messagesController: MessageSequenceController,
             itemsToReconfigure: [ItemType] = [],
             showLoadMore: Bool = false) {

        self.messageSequenceController = messagesController

        // Don't show deleted messages
        let messages = messagesController.messageArray.filter { message in
            return !message.isDeleted
        }

        // The newest message is at the bottom, so reverse the order.
        var messageItems = messages.map { message in
            return ItemType.message(messageId: message.id)
        }
        messageItems = messageItems.reversed()

        if self.shouldPrepareToSend {
            messageItems.append(.placeholder)
        }

        if showLoadMore {
            messageItems.insert(.loadMore, at: 0)
        } else {
            messageItems.insert(.initial, at: 0)
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
                                        (messagesController: MessageSequenceController,
                                         messageId: String,
                                         showDetail: Bool,
                                         collectionView: UICollectionView)>
    typealias LoadMoreCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, UICollectionView?>
    typealias PlaceholderMessageCellRegistration
    = UICollectionView.CellRegistration<PlaceholderMessageCell, UICollectionView?>
    typealias InitialMessageCellRegistration
    = UICollectionView.CellRegistration<InitialMessageCell, (MessageSequenceController, UICollectionView?)>

    static func createMessageCellRegistration() -> MessageCellRegistration {
        return MessageCellRegistration { cell, indexPath, item in
            let messagesController = item.messagesController
            guard let message = messagesController.messageArray.first(where: { message in
                message.id == item.messageId
            }) else {
                logDebug("WARNING: Message not found in the controller. Make sure that a sequence controller was assigned.")
                return }

            cell.shouldShowDetailBar = item.showDetail
            cell.configure(with: message)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreCellRegistration {
        return LoadMoreCellRegistration { cell, indexPath, item in }
    }

    static func createPlaceholderMessageCellRegistration() -> PlaceholderMessageCellRegistration {
        return PlaceholderMessageCellRegistration { cell, indexPath, itemIdentifier in }
    }
    
    static func createInitialCellRegistration() -> InitialMessageCellRegistration {
        return InitialMessageCellRegistration { cell, indexPath, item in
            cell.configure(with: item.0)
        }
    }
}

// MARK: - TimelineCollectionViewLayoutDataSource

extension MessageSequenceCollectionViewDataSource: MessagesTimeMachineCollectionViewLayoutDataSource {

    func getTimeMachineItem(forItemAt indexPath: IndexPath) -> TimeMachineLayoutItemType {
        guard let item = self.itemIdentifier(for: indexPath) else {
            return TimeMachineLayoutItem(date: Date.distantPast)
        }

        return self.getTimeMachineItem(forItem: item)
    }

    private func getTimeMachineItem(forItem item: ItemType) -> TimeMachineLayoutItemType {
        switch item {
        case .message(let messageId, _):
            guard let message = self.messageSequenceController.getMessage(withId: messageId) else {
                return TimeMachineLayoutItem(date: .distantPast)
            }
            return TimeMachineLayoutItem(date: message.createdAt)
        case .loadMore:
            // Get the oldest loaded message and set the date slightly before that.
            guard let oldestMessage = self.messageSequenceController.messageArray.last else {
                return TimeMachineLayoutItem(date: .distantPast)
            }

            return TimeMachineLayoutItem(date: oldestMessage.createdAt - 0.001)
        case .initial:
            return TimeMachineLayoutItem(date: .distantPast)
        case .placeholder:
            return TimeMachineLayoutItem(date: .distantFuture)
        }
    }

    func isUserCreatedItem(at indexPath: IndexPath) -> Bool {
        guard let item = self.itemIdentifier(for: indexPath) else { return false }

        switch item {
        case .message(let messageId, _):
            // We should always scroll to the end when inserting messages from our selves
            guard let message = self.messageSequenceController.getMessage(withId: messageId) else {
                return false
            }
            return message.isFromCurrentUser
        case .loadMore, .initial:
            return false
        case .placeholder:
            return true
        }
    }
}

private struct TimeMachineLayoutItem: TimeMachineLayoutItemType {
    var date: Date
}
