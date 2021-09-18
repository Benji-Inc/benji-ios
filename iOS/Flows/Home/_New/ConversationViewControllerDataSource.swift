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
        case basic(ChannelId)
    }

    enum ItemType: Hashable {
        case message(MessageId)
    }

    var handleDeleteMessage: ((ChatMessage) -> Void)?

    private let contextMenuDelegate: ContextMenuInteractionDelegate

    override init(collectionView: UICollectionView) {
        self.contextMenuDelegate = ContextMenuInteractionDelegate(collectionView: collectionView)

        super.init(collectionView: collectionView)

        self.contextMenuDelegate.dataSource = self
    }

    private let messageCellConfig = UICollectionView.CellRegistration<new_MessageCell, (ChannelId, MessageId)>
    { cell, indexPath, item in

        let messageController = ChatClient.shared.messageController(cid: item.0, messageId: item.1)
        // Configure the cell
        cell.contentView.set(backgroundColor: .red)
        if messageController.message?.type == .deleted {
            cell.textView.text = "DELETED"
        } else {
            cell.textView.text = messageController.message?.text
        }
        cell.contentView.setNeedsLayout()
    }

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch section {
        case .basic(let channelID):
            switch item {
            case .message(let messageID):
                let cell = collectionView.dequeueConfiguredReusableCell(using: self.messageCellConfig,
                                                                    for: indexPath,
                                                                    item: (channelID, messageID))

                let interaction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
                cell.addInteraction(interaction)
                return cell
            }
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
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

        guard let indexPath = self.collectionView.indexPathForItem(at: location) else { return nil }

        // Get the conversation and message IDs.
        guard let sectionItem = self.dataSource?.sectionIdentifier(for: indexPath.section),
              let messageItem = self.dataSource?.itemIdentifier(for: indexPath) else { return nil }


        switch sectionItem {
        case .basic(let channelID):
            switch messageItem {
            case .message(let messageID):
                let messageController = ChatClient.shared.messageController(cid: channelID,
                                                                            messageId: messageID)

                return UIContextMenuConfiguration(identifier: nil,
                                                  previewProvider: nil) { elements in
                    return self.makeContextMenu(for: messageController, at: indexPath)
                }
            }
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

extension LazyCachedMapCollection where Element == ChatMessage {

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
