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

    // Model for the main section of the conversation or thread.
    // The parent message is root message that has replies in a thread. It is nil for a conversation.
    struct SectionType: Hashable {
        let cid: ConversationID
        let parentMessageID: MessageId?

        var isThread: Bool { return self.parentMessageID.exists }
        init(cid: ConversationID, parentMessageID: MessageId? = nil) {
            self.cid = cid
            self.parentMessageID = parentMessageID
        }
    }

    enum ItemType: Hashable {
        case message(MessageId)
        case loadMore
    }

    enum MessageStyle {
        case conversation
        case thread
    }

    var handleDeleteMessage: ((Message) -> Void)?
    var handleLoadMoreMessages: CompletionOptional = nil
    @Published var conversationUIState: ConversationUIState = .read

    var messageStyle: MessageStyle = .conversation
    
    private let contextMenuDelegate: ContextMenuInteractionDelegate

    // Cell registration
    private let messageCellRegistration = ConversationCollectionViewDataSource.createMessageCellRegistration()
    private let threadMessageCellRegistration
    = ConversationCollectionViewDataSource.createThreadMessageCellRegistration()
    private let loadMoreMessagesCellRegistration
    = ConversationCollectionViewDataSource.createLoadMoreCellRegistration()

    required init(collectionView: UICollectionView) {
        self.contextMenuDelegate = ContextMenuInteractionDelegate(collectionView: collectionView)

        super.init(collectionView: collectionView)

        self.contextMenuDelegate.dataSource = self
    }

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .message(let messageID):
            let cell: UICollectionViewCell
            switch self.messageStyle {
            case .conversation:
                cell = collectionView.dequeueConfiguredReusableCell(using: self.messageCellRegistration,
                                                                    for: indexPath,
                                                                    item: (section.cid, messageID, self))
            case .thread:
                cell = collectionView.dequeueConfiguredReusableCell(using: self.threadMessageCellRegistration,
                                                                    for: indexPath,
                                                                    item: (section.cid, messageID, self))
            }

            let interaction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
            cell.contentView.addInteraction(interaction)
            return cell
        case .loadMore:
            return collectionView.dequeueConfiguredReusableCell(using: self.loadMoreMessagesCellRegistration,
                                                                for: indexPath,
                                                                item: String())
        }
    }

    /// Updates the datasource with the passed in array of message changes.
    func update(with changes: [ListChange<Message>],
                conversationController: ConversationControllerType,
                collectionView: UICollectionView) async {

        let conversation = conversationController.conversation

        var snapshot = self.snapshot()

        let sectionID = ConversationSection(cid: conversation.cid,
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

        // If this gets set to true, we should scroll to the most recent message after applying the snapshot
        var scrollToLatestMessage = false

        for change in changes {
            switch change {
            case .insert(let message, let index):
                snapshot.insertItems([.message(message.id)],
                                     in: sectionID,
                                     atIndex: index.item)
                if message.isFromCurrentUser {
                    scrollToLatestMessage = true
                }
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

        await Task.onMainActorAsync { [snapshot = snapshot, scrollToLatestMessage = scrollToLatestMessage] in
            self.apply(snapshot)

            // Scroll to the latest message if needed and reconfigure cells as needed.
            if scrollToLatestMessage, let sectionIndex = snapshot.indexOfSection(sectionID) {
                let latestMessageIndex = IndexPath(item: 0, section: sectionIndex)
                switch self.messageStyle {
                case .conversation:
                    // Conversations have the latest message at the first index.
                    collectionView.scrollToItem(at: latestMessageIndex, at: .centeredHorizontally, animated: true)
                case .thread:
                    // Inserting a message can cause the visual state of the previous message to change.
                    self.reconfigureItem(atIndex: 1, in: sectionID)
                    collectionView.scrollToItem(at: latestMessageIndex, at: .bottom, animated: true)
                }
            }
        }
    }
}

private class ContextMenuInteractionDelegate: NSObject, UIContextMenuInteractionDelegate {

    weak var dataSource: ConversationCollectionViewDataSource?
    let collectionView: UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        let locationInCollectionView = interaction.location(in: self.collectionView)
        guard let indexPath = self.collectionView.indexPathForItem(at: locationInCollectionView) else {
            return nil
        }

        // Get the conversation and message IDs.
        guard let sectionItem = self.dataSource?.sectionIdentifier(for: indexPath.section),
              let messageItem = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }

        switch messageItem {
        case .message(let messageID):
            let messageController = ChatClient.shared.messageController(cid: sectionItem.cid,
                                                                        messageId: messageID)

            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { elements in
                return self.makeContextMenu(for: messageController, at: indexPath)
            }
        case .loadMore:
            return nil
        }
    }

    private func makeContextMenu(for messageController: ChatMessageController,
                                 at indexPath: IndexPath) -> UIMenu {

        guard let message = messageController.message else { return UIMenu() }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { action in

            self.dataSource?.handleDeleteMessage?(message)
        }

        let deleteMenu = UIMenu(title: "Delete",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])


        if message.isFromCurrentUser {
            let children = [deleteMenu]
            return UIMenu(title: "", children: children)
        }

        // Create and return a UIMenu with the share action
        return UIMenu()
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
        return ConversationItem.message(self.id)
    }
}
