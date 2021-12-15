//
//  ConversationViewControllerDataSource.swift
//  ConversationViewControllerDataSource
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationListSection = ConversationListCollectionViewDataSource.SectionType
typealias ConversationListItem = ConversationListCollectionViewDataSource.ItemType

class ConversationListCollectionViewDataSource: CollectionViewDataSource<ConversationListSection,
                                                ConversationListItem> {

    /// Model for the main section of the conversation list collection.
    struct SectionType: Hashable {
        let conversationsController: ConversationListController
    }

    enum ItemType: Hashable {
        case conversation(ConversationId)
        case loadMore
    }

    var handleSelectedMessage: ((ConversationId, MessageId, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationId, MessageId) -> Void)?
    
    var handleLoadMoreMessages: CompletionOptional = nil
    @Published var conversationUIState: ConversationUIState = .read

    var layoutForDropZone = false {
        didSet {
            self.reconfigureAllItems()
        }
    }

    /// The conversation ID of the conversation that is preparing to send, if any.
    private var conversationPreparingToSend: ConversationId?

    // Cell registration
    private let conversationCellRegistration
    = ConversationListCollectionViewDataSource.createConversationCellRegistration()
    private let loadMoreMessagesCellRegistration
    = ConversationListCollectionViewDataSource.createLoadMoreCellRegistration()

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .conversation(let cid):
            let conversationCell
            = collectionView.dequeueConfiguredReusableCell(using: self.conversationCellRegistration,
                                                           for: indexPath,
                                                           item: (cid, self))
            conversationCell.handleTappedMessage = { [unowned self] cid, messageID, content in
                self.handleSelectedMessage?(cid, messageID, content)
            }
            conversationCell.handleEditMessage = { [unowned self] cid, messageID in
                self.handleEditMessage?(cid, messageID)
            }

            return conversationCell
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

    /// Updates the datasource with the passed in array of conversation changes.
    func update(with changes: [ListChange<Conversation>],
                conversationController: ConversationListController,
                collectionView: UICollectionView) async {

        var snapshot = self.snapshot()

        let sectionID = ConversationListSection(conversationsController: conversationController)

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
                snapshot.insertItems([.conversation(conversation.cid)],
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

    func set(conversationPreparingToSend: ConversationId?, reloadData: Bool) {
        self.conversationPreparingToSend = conversationPreparingToSend

        if reloadData {
            self.reconfigureAllItems()
        }
    }
}

// MARK: - Cell Registration

extension ConversationListCollectionViewDataSource {

    typealias ConversationCellRegistration
    = UICollectionView.CellRegistration<ConversationMessagesCell,
                                        (channelID: ChannelId,
                                         dataSource: ConversationListCollectionViewDataSource)>

    typealias LoadMoreMessagesCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, String>

    static func createConversationCellRegistration() -> ConversationCellRegistration {
        return ConversationCellRegistration { cell, indexPath, item in
            let conversationController = ChatClient.shared.channelController(for: item.channelID)

            if conversationController.cid == item.dataSource.conversationPreparingToSend {
                cell.set(isPreparedToSend: true)
            } else {
                cell.set(isPreparedToSend: false)
            }

            cell.set(layoutForDropZone: item.dataSource.layoutForDropZone)
            cell.set(conversation: conversationController.conversation)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreMessagesCellRegistration {
        return LoadMoreMessagesCellRegistration { cell, indexPath, itemIdentifier in }
    }
}


// MARK: - Collection Convenience Functions

extension Array where Element == Conversation {
    
    var asConversationCollectionItems: [ConversationListItem] {
        return self.map { conversation in
            return conversation.asConversationCollectionItem
        }
    }
}

extension Conversation {

    var asConversationCollectionItem: ConversationListItem {
        return ConversationListItem.conversation(self.cid)
    }
}
