//
//  ConversationCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = ChannelId

    var currentItem: ChannelId?

    let content = ConversationContentView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
    }

    func configure(with item: ChannelId) {
        let conversation = ChatClient.shared.channelController(for: item).conversation
        self.content.configure(with: conversation)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes)
    -> UICollectionViewLayoutAttributes {
        
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 60)
        return layoutAttributes
    }

    override func canHandleStationaryPress() -> Bool {
        return false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
        self.content.roundCorners()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.content.stackedAvatarView.reset()
        self.currentItem = nil
    }
}
