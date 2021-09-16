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
        case messageThread(MessageId)
    }

    enum ItemType: Hashable {
        case message(MessageId)
    }

    private let messageCellConfig = UICollectionView.CellRegistration<new_MessageCell, (ChannelId, MessageId)>
    { cell, indexPath, item in
        let messageController = ChatClient.shared.messageController(cid: item.0, messageId: item.1)
        // Configure the cell
        cell.contentView.set(backgroundColor: .red)
        cell.textView.text = messageController.message?.text
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
                return collectionView.dequeueConfiguredReusableCell(using: self.messageCellConfig,
                                                                    for: indexPath,
                                                                    item: (channelID, messageID))
            }
        case .messageThread(_):
            return nil
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
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
