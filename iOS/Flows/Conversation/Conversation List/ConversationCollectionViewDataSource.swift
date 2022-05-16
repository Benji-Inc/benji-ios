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

    /// Model for the main section of the conversation.
    struct SectionType: Hashable { }

    enum ItemType: Hashable {
        case conversation(ConversationId)
    }

    // Input handling
    weak var messageContentDelegate: MessageContentDelegate?
    var handleCollectionViewTapped: CompletionOptional = nil
    var handleAddPeopleSelected: CompletionOptional = nil

    /// The conversation ID of the conversation that is preparing to send, if any.
    private var conversationPreparingToSend: ConversationId?

    // Cell registration
    private let conversationCellRegistration
    = ConversationCollectionViewDataSource.createConversationCellRegistration()
    
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
            conversationCell.handleAddMembersTapped = { [unowned self] in
                self.handleAddPeopleSelected?()
            }

            return conversationCell

        }
    }

    /// Updates the datasource with to reflect the conversation controller.
    func update(with conversationController: ConversationController) async {
        let updatedSnapshot = self.updatedSnapshot(with: conversationController)
        await self.apply(updatedSnapshot)
    }

    func updatedSnapshot(with conversationController: ConversationController)
    -> NSDiffableDataSourceSnapshot<ConversationSection, ConversationItem> {

        var snapshot = self.snapshot()

        let sectionID = ConversationSection()

        var updatedItems: [ConversationItem] = []
        if let conversation = conversationController.conversation {
            updatedItems.append(ConversationItem.conversation(conversation.cid))
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

extension ConversationCollectionViewDataSource {

    typealias ConversationCellRegistration
    = UICollectionView.CellRegistration<ConversationMessagesCell,
                                        (channelID: ChannelId,
                                         uiState: ConversationUIState,
                                         dataSource: ConversationCollectionViewDataSource)>

    static func createConversationCellRegistration() -> ConversationCellRegistration {
        return ConversationCellRegistration { cell, indexPath, item in
            let conversationController = ChatClient.shared.channelController(for: item.channelID)

            let isPreparedToSend = conversationController.cid == item.dataSource.conversationPreparingToSend
            if let conversation = conversationController.conversation {
                cell.set(conversation: conversation, shouldPrepareToSend: isPreparedToSend)
            }
            
            cell.set(state: item.uiState)
        }
    }
}
