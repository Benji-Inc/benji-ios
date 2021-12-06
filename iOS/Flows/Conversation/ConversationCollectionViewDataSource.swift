//
//  ConversationViewControllerDataSource.swift
//  ConversationViewControllerDataSource
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationSection = ConversationCollectionViewDataSource.SectionType
typealias ConversationItem = ConversationCollectionViewDataSource.ItemType

class ConversationCollectionViewDataSource: CollectionViewDataSource<ConversationSection,
                                            ConversationItem> {

    /// Model for the main section of the conversation or thread.
    /// The parent message is root message that has replies in a thread. It is nil for a conversation.
    struct SectionType: Hashable {
        let sectionID: String
        let conversationsController: ConversationListController?
        let parentMessageID: MessageId?

        var isConversationList: Bool { return self.conversationsController.exists }
        var isThread: Bool { return self.parentMessageID.exists }

        init(sectionID: String,
             conversationsController: ConversationListController? = nil,
             parentMessageID: MessageId? = nil) {

            self.sectionID = sectionID
            self.conversationsController = conversationsController
            self.parentMessageID = parentMessageID
        }
    }

    enum ItemType: Hashable {
        case messages(String)
        case loadMore
    }

    var handleSelectedMessage: ((ConversationMessageItem, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationMessageItem) -> Void)?

    
    var handleLoadMoreMessages: CompletionOptional = nil
    @Published var conversationUIState: ConversationUIState = .read

    // Cell registration
    private let messageCellRegistration = ConversationCollectionViewDataSource.createMessageCellRegistration()
    private let conversationCellRegistration
    = ConversationCollectionViewDataSource.createConversationCellRegistration()

    private let loadMoreMessagesCellRegistration
    = ConversationCollectionViewDataSource.createLoadMoreCellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .messages(let itemID):
            if section.isThread {
                let cid = try! ConversationID(cid: section.sectionID)
                let threadCell
                = collectionView.dequeueConfiguredReusableCell(using: self.messageCellRegistration,
                                                               for: indexPath,
                                                               item: (cid, itemID, self))
                threadCell.content.handleEditMessage = { [unowned self] item in
                    self.handleEditMessage?(item)
                }
                return threadCell

            } else if section.isConversationList {
                let cid = try! ConversationID(cid: itemID)

                let messageCell
                = collectionView.dequeueConfiguredReusableCell(using: self.conversationCellRegistration,
                                                               for: indexPath,
                                                               item: (cid, self))
                messageCell.handleTappedMessage = { [unowned self] item, content in
                    self.handleSelectedMessage?(item, content)
                }
                messageCell.handleEditMessage = { [unowned self] item in 
                    self.handleEditMessage?(item)
                }

                return messageCell
            } else {
                return nil
            }
        case .loadMore:
            let loadMoreCell
            = collectionView.dequeueConfiguredReusableCell(using: self.loadMoreMessagesCellRegistration,
                                                           for: indexPath,
                                                           item: String())
            loadMoreCell.handleLoadMoreMessages = { [unowned self] in
                self.handleLoadMoreMessages?()
            }
            return loadMoreCell
        }
    }

    /// Updates the datasource with the passed in array of message changes.
    func update(with changes: [ListChange<Message>],
                conversationController: ConversationControllerType,
                collectionView: UICollectionView) async {

        let conversation = conversationController.conversation

        var snapshot = self.snapshot()

        let sectionID = ConversationSection(sectionID: conversation.cid.description,
                                            parentMessageID: conversationController.rootMessage?.id)

        // If there's more than one change, reload all of the data.
        guard changes.count == 1 else {
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
            snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                 toSection: sectionID)
            if !conversationController.hasLoadedAllPreviousMessages {
                snapshot.appendItems([.loadMore], toSection: sectionID)
            }
            await self.apply(snapshot)
            return
        }

        for change in changes {
            switch change {
            case .insert(let message, let index):
                snapshot.insertItems([.messages(message.id)],
                                     in: sectionID,
                                     atIndex: index.item)
            case .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
                snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                     toSection: sectionID)
            case .update(let message, _):
                snapshot.reconfigureItems([message.asConversationCollectionItem])
            case .remove(let message, _):
                snapshot.deleteItems([message.asConversationCollectionItem])
            }
        }

        // Only show the load more cell if there are previous messages to load.
        snapshot.deleteItems([.loadMore])
        if !conversationController.hasLoadedAllPreviousMessages {
            snapshot.appendItems([.loadMore], toSection: sectionID)
        }

        await Task.onMainActorAsync { [snapshot = snapshot] in
            self.apply(snapshot)
        }
    }

    /// Updates the datasource with the passed in array of conversation changes.
    func update(with changes: [ListChange<Conversation>],
                conversationController: ConversationListController,
                collectionView: UICollectionView) async {


        var snapshot = self.snapshot()

        let sectionID = ConversationSection(sectionID: "channelList",
                                            conversationsController: conversationController)

        // If there's more than one change, reload all of the data.
        guard changes.count == 1 else {
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
            snapshot.appendItems(conversationController.conversations.asConversationCollectionItems,
                                 toSection: sectionID)
            if !conversationController.hasLoadedAllPreviousChannels {
                snapshot.appendItems([.loadMore], toSection: sectionID)
            }
            await self.apply(snapshot)
            return
        }

        for change in changes {
            switch change {
            case .insert(let conversation, let index):
                snapshot.insertItems([.messages(conversation.id)],
                                     in: sectionID,
                                     atIndex: index.item)
            case .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
                snapshot.appendItems(conversationController.conversations.asConversationCollectionItems,
                                     toSection: sectionID)
            case .update(let message, _):
                snapshot.reconfigureItems([message.asConversationCollectionItem])
            case .remove(let message, _):
                snapshot.deleteItems([message.asConversationCollectionItem])
            }
        }

        // Only show the load more cell if there are previous messages to load.
        snapshot.deleteItems([.loadMore])
        if !conversationController.hasLoadedAllPreviousChannels {
            snapshot.appendItems([.loadMore], toSection: sectionID)
        }

        await Task.onMainActorAsync { [snapshot = snapshot] in
            self.apply(snapshot)
        }
    }
}

extension LazyCachedMapCollection where Element == Message {

    /// Convenience function to convert Stream chat messages into the ItemType of a ConversationCollectionViewDataSource.
    var asConversationCollectionItems: [ConversationItem] {
        return self.map { message in
            return message.asConversationCollectionItem
        }
    }
}

extension ChatMessage {

    /// Convenience function to convert Stream chat messages into the ItemType of a ConversationCollectionViewDataSource.
    var asConversationCollectionItem: ConversationItem {
        return ConversationItem.messages(self.id)
    }
}

extension Array where Element == Conversation {
    
    var asConversationCollectionItems: [ConversationItem] {
        return self.map { conversation in
            return conversation.asConversationCollectionItem
        }
    }
}

extension Conversation {

    var asConversationCollectionItem: ConversationItem {
        return ConversationItem.messages(self.cid.description)
    }
}
