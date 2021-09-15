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

    let textView = TextView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.textView.width = self.contentView.width
        self.textView.sizeToFit()
        self.textView.centerOnXAndY()
    }
}

class ConversationCollectionViewDataSource: CollectionViewDataSource<ConversationCollectionViewDataSource.SectionType,
                                            ConversationCollectionViewDataSource.ItemType> {

    enum SectionType: Hashable {
        case messageThread(MessageId)
    }

    enum ItemType: Hashable {
        case message(ChatMessage)
    }

    private let messageCellConfig
    = UICollectionView.CellRegistration<new_MessageCell, ChatMessage>
    { cell, indexPath, itemIdentifier in
        // Configure the cell
        cell.contentView.set(backgroundColor: .red)
        cell.textView.text = itemIdentifier.text
        cell.contentView.setNeedsLayout()
    }

    override func dequeueCell(with collectionView: UICollectionView,
                              indexPath: IndexPath,
                              section: SectionType,
                              item: ItemType) -> UICollectionViewCell? {

        switch item {
        case .message(let message):
            return collectionView.dequeueConfiguredReusableCell(using: self.messageCellConfig,
                                                                for: indexPath,
                                                                item: message)
        }
    }

    override func dequeueSupplementaryView(with collectionView: UICollectionView,
                                           kind: String,
                                           section: SectionType,
                                           indexPath: IndexPath) -> UICollectionReusableView? {
        return nil
    }

}

extension ChatMessage {

    /// Convenience function to convert Stream chat messages into the ItemType of a ConversationCollectionViewDataSource.
    var asConversationCollectionItem: ConversationCollectionItem {
        return ConversationCollectionItem.message(self)
    }
}
