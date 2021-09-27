//
//  ConversationViewControllerDataSource.swift
//  ConversationViewControllerDataSource
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationCollectionSection = ConversationCollectionViewDataSource.SectionType
typealias ConversationCollectionItem = ConversationCollectionViewDataSource.ItemType

class ConversationCollectionViewDataSource: CollectionViewDataSource<ConversationCollectionViewDataSource.SectionType,
                                            ConversationCollectionViewDataSource.ItemType> {

    enum SectionType: Hashable {
        case conversation(ChannelId)
        case loadMore
    }

    enum ItemType: Hashable {
        case message(MessageId)
        case loadMore
    }

    var handleDeleteMessage: ((Message) -> Void)?
    var handleLoadMoreMessages: CompletionOptional = nil

    private let contextMenuDelegate: ContextMenuInteractionDelegate
    private let messageCellRegistration = ConversationCollectionViewDataSource.createMessageCellRegistration()
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
            guard case let .conversation(channelID) = section else { return nil }

            let cell = collectionView.dequeueConfiguredReusableCell(using: self.messageCellRegistration,
                                                                    for: indexPath,
                                                                    item: (channelID, messageID, self))

            let interaction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
            cell.addInteraction(interaction)
            return cell
        case .loadMore:
            return collectionView.dequeueConfiguredReusableCell(using: self.loadMoreMessagesCellRegistration,
                                                                for: indexPath,
                                                                item: "Test")
        }
    }

    /// Updates the datasource with the passed in array of message changes.
    func update(with changes: [ListChange<Message>],
                conversationController: ConversationController,
                collectionView: UICollectionView) async {

        guard let conversation = conversationController.conversation else { return }

        var snapshot = self.snapshot()

        // Only show the load more cell if there are previous messages to load.
        snapshot.deleteItems([.loadMore])
        if !conversationController.hasLoadedAllPreviousMessages {
            snapshot.appendItems([.loadMore], toSection: .loadMore)
        }

        let sectionID = ConversationCollectionSection.conversation(conversation.cid)

        // If there's more than one change, reload all of the data.
        guard changes.count == 1 else {
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
            snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                 toSection: sectionID)
            await self.applySnapshotKeepingVisualOffset(snapshot,
                                                        collectionView: collectionView)
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
                scrollToLatestMessage = true
            case .move:
                snapshot.deleteItems(snapshot.itemIdentifiers(inSection: sectionID))
                snapshot.appendItems(conversationController.messages.asConversationCollectionItems,
                                     toSection: sectionID)
            case .update(let message, _):
                snapshot.reloadItems([message.asConversationCollectionItem])
            case .remove(let message, _):
                snapshot.deleteItems([message.asConversationCollectionItem])
            }
        }

        await Task.onMainActorAsync { [snapshot = snapshot, scrollToLatestMessage = scrollToLatestMessage] in
            self.apply(snapshot)

            if scrollToLatestMessage, let sectionIndex = snapshot.indexOfSection(sectionID) {
                let items = snapshot.itemIdentifiers(inSection: .conversation(conversation.cid))
                let lastIndex = IndexPath(item: items.count - 1, section: sectionIndex)
                collectionView.scrollToItem(at: lastIndex, at: .centeredHorizontally, animated: true)
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
            guard case let .conversation(channelID) = sectionItem else { return nil }
            let messageController = ChatClient.shared.messageController(cid: channelID,
                                                                        messageId: messageID)

            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { elements in
                return self.makeContextMenu(for: messageController, at: indexPath)
            }
        case .loadMore:
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
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
    var asConversationCollectionItems: [ConversationCollectionItem] {
        return self.map { message in
            return message.asConversationCollectionItem
        }
    }
}

extension ChatMessage {

    /// Convenience function to convert Stream chat messages into the ItemType of a ConversationCollectionViewDataSource.
    var asConversationCollectionItem: ConversationCollectionItem {
        return ConversationCollectionItem.message(self.id)
    }
}
