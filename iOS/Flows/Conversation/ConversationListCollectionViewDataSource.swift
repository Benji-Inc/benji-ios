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
        case newConversation
    }

    var handleSelectedMessage: ((ConversationId, MessageId, MessageContentView) -> Void)?
    var handleEditMessage: ((ConversationId, MessageId) -> Void)?
    
    var handleLoadMoreMessages: CompletionOptional = nil
    @Published var conversationUIState: ConversationUIState = .read

    /// The conversation ID of the conversation that is preparing to send, if any.
    private var conversationPreparingToSend: ConversationId?

    // Cell registration
    private let conversationCellRegistration
    = ConversationListCollectionViewDataSource.createConversationCellRegistration()
    private let loadMoreMessagesCellRegistration
    = ConversationListCollectionViewDataSource.createLoadMoreCellRegistration()
    private let newConversationCellRegistration
    = ConversationListCollectionViewDataSource.createNewConversationCellRegistration()

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
                                                           item: self)
            loadMoreCell.handleLoadMoreMessages = { [unowned self] in
                self.handleLoadMoreMessages?()
            }
            return loadMoreCell
        case .newConversation:
            let newConversationCell
            = collectionView.dequeueConfiguredReusableCell(using: self.newConversationCellRegistration,
                                                           for: indexPath,
                                                           item: self)
            return newConversationCell
        }
    }

    /// Updates the datasource with the passed in array of conversation changes.
    func update(with conversationListController: ConversationListController) async {
        let updatedSnapshot = self.updatedSnapshot(with: conversationListController)
        await self.apply(updatedSnapshot)
    }

    func updatedSnapshot(with conversationListController: ConversationListController)
    -> NSDiffableDataSourceSnapshot<ConversationListSection, ConversationListItem> {

        var snapshot = self.snapshot()

        let sectionID = ConversationListSection(conversationsController: conversationListController)

        var updatedItems: [ConversationListItem] = []

        if !conversationListController.hasLoadedAllPreviousChannels
            && conversationListController.conversations.count > 0 {

            updatedItems.append(.loadMore)
        }
        updatedItems.append(contentsOf: conversationListController.conversations.asConversationCollectionItems)
        updatedItems.append(.newConversation)

        snapshot.setItems(updatedItems, in: sectionID)

        return snapshot
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
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, ConversationListCollectionViewDataSource>

    typealias NewConversationCellRegistration
    = UICollectionView.CellRegistration<PlaceholderConversationCell, ConversationListCollectionViewDataSource>

    static func createConversationCellRegistration() -> ConversationCellRegistration {
        return ConversationCellRegistration { cell, indexPath, item in
            let conversationController = ChatClient.shared.channelController(for: item.channelID)

            if conversationController.cid == item.dataSource.conversationPreparingToSend {
                cell.set(isPreparedToSend: true)
            } else {
                cell.set(isPreparedToSend: false)
            }

            cell.set(conversation: conversationController.conversation)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreMessagesCellRegistration {
        return LoadMoreMessagesCellRegistration { cell, indexPath, itemIdentifier in }
    }

    static func createNewConversationCellRegistration() -> NewConversationCellRegistration {
        return NewConversationCellRegistration { cell, indexPath, itemIdentifier in }
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
