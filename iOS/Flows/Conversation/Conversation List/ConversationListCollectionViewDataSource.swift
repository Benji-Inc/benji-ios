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
        case upsell
        case invest
    }

    // Input handling
    weak var messageContentDelegate: MessageContentDelegate?
    var handleCollectionViewTapped: CompletionOptional = nil 
    
    var handleLoadMoreMessages: CompletionOptional = nil
    var handleAddPeopleSelected: CompletionOptional = nil
    var handleInvestmentSelected: CompletionOptional = nil
    
    var handleDidTapClose: ((ItemType) -> Void)?

    /// The conversation ID of the conversation that is preparing to send, if any.
    private var conversationPreparingToSend: ConversationId?

    // Cell registration
    private let conversationCellRegistration
    = ConversationListCollectionViewDataSource.createConversationCellRegistration()
    private let loadMoreMessagesCellRegistration
    = ConversationListCollectionViewDataSource.createLoadMoreCellRegistration()
    private let newConversationCellRegistration
    = ConversationListCollectionViewDataSource.createNewConversationCellRegistration()
    private let invitationUpsellCellRegistration
    = ConversationListCollectionViewDataSource.createInvitationUpsellCellRegistration()
    private let investmentUpsellCellRegistration
    = ConversationListCollectionViewDataSource.createInvestmentUpsellCellRegistration()
    
    var uiState: ConversationUIState = .read

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .conversation(let cid):
            let conversationCell
            = collectionView.dequeueConfiguredReusableCell(using: self.conversationCellRegistration,
                                                           for: indexPath,
                                                           item: (cid, self.uiState, self))
            conversationCell.messageContentDelegate = self.messageContentDelegate
            conversationCell.handleCollectionViewTapped = { [unowned self] in
                self.handleCollectionViewTapped?()
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
        case .upsell:
            let cell
            = collectionView.dequeueConfiguredReusableCell(using: self.invitationUpsellCellRegistration,
                                                           for: indexPath,
                                                           item: self)
            cell.didSelectClose = { [unowned self]  in
                self.handleDidTapClose?(item)
            }
            cell.didSelectAddPeople = { [unowned self] in
                self.handleAddPeopleSelected?()
            }
            return cell
        case .invest:
            let cell
            = collectionView.dequeueConfiguredReusableCell(using: self.investmentUpsellCellRegistration,
                                                           for: indexPath,
                                                           item: self)
            cell.didSelectClose = { [unowned self]  in
                self.handleDidTapClose?(item)
            }
            cell.didTapInvest = { [unowned self] in
                self.handleInvestmentSelected?()
            }
            return cell
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
        
        if UserDefaultsManager.getBool(for: .shouldShowGroupsUpsell, defaultValue: true) {
            updatedItems.append(.upsell)
        }
        
        if UserDefaultsManager.getBool(for: .shouldShowInvestUpsell, defaultValue: true) {
            updatedItems.append(.invest)
        }
      
        snapshot.setItems(updatedItems, in: sectionID)

        return snapshot
    }

    func set(conversationPreparingToSend: ConversationId?) {
        self.conversationPreparingToSend = conversationPreparingToSend

        self.reconfigureAllItems()
    }
}

// MARK: - Cell Registration

extension ConversationListCollectionViewDataSource {

    typealias ConversationCellRegistration
    = UICollectionView.CellRegistration<ConversationMessagesCell,
                                        (channelID: ChannelId,
                                         uiState: ConversationUIState,
                                         dataSource: ConversationListCollectionViewDataSource)>

    typealias LoadMoreMessagesCellRegistration
    = UICollectionView.CellRegistration<LoadMoreMessagesCell, ConversationListCollectionViewDataSource>

    typealias NewConversationCellRegistration
    = UICollectionView.CellRegistration<PlaceholderConversationCell, ConversationListCollectionViewDataSource>
    
    typealias InvitationUpsellCellRegistration
    = UICollectionView.CellRegistration<InvitationUpsellCell, ConversationListCollectionViewDataSource>
    
    typealias InvestmentUpsellCellRegistration
    = UICollectionView.CellRegistration<InvestmentUpsellCell, ConversationListCollectionViewDataSource>

    static func createConversationCellRegistration() -> ConversationCellRegistration {
        return ConversationCellRegistration { cell, indexPath, item in
            let conversationController = ChatClient.shared.channelController(for: item.channelID)

            let isPreparedToSend = conversationController.cid == item.dataSource.conversationPreparingToSend
            cell.set(conversation: conversationController.conversation, shouldPrepareToSend: isPreparedToSend)
            cell.set(state: item.uiState)
        }
    }

    static func createLoadMoreCellRegistration() -> LoadMoreMessagesCellRegistration {
        return LoadMoreMessagesCellRegistration { cell, indexPath, itemIdentifier in }
    }

    static func createNewConversationCellRegistration() -> NewConversationCellRegistration {
        return NewConversationCellRegistration { cell, indexPath, item in
            cell.set(state: item.uiState)
        }
    }
    
    static func createInvitationUpsellCellRegistration() -> InvitationUpsellCellRegistration {
        return InvitationUpsellCellRegistration { cell, indexPath, item in
            cell.set(state: item.uiState)
        }
    }
    
    static func createInvestmentUpsellCellRegistration() -> InvestmentUpsellCellRegistration {
        return InvestmentUpsellCellRegistration { cell, indexPath, item in
            cell.set(state: item.uiState)
        }
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
