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

class new_MessageCell: UICollectionViewCell {

}

class ConversationCollectionViewDataSource: CollectionViewDataSource<ConversationCollectionViewDataSource.SectionType,
                                            ConversationCollectionViewDataSource.ItemType> {

    enum SectionType: Int, CaseIterable {
        case messages
    }

    enum ItemType: Hashable {
        case message(ChatMessage)
    }

    private let messageCellConfig
    = UICollectionView.CellRegistration<new_MessageCell, ConversationCollectionItem>
    { cell, indexPath, itemIdentifier in
        // Configure the cell
        cell.contentView.set(backgroundColor: .red)
    }

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .message:
            return collectionView.dequeueConfiguredReusableCell(using: self.messageCellConfig,
                                                                for: indexPath,
                                                                item: item)
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }

}

extension Array where Element == ChatMessage {

    /// Convenience function to convert Stream chat messages into the ItemType of a ConversationCollectionViewDataSource.
    var asConversationCollectionItems: [ConversationCollectionItem] {
        return self.map { chatMessage in
            return ConversationCollectionItem.message(chatMessage)
        }
    }
}
