//
//  ChannelCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class ChannelCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = DisplayableChannel

    var currentItem: DisplayableChannel?

    private let content = ChannelContentView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
    }

    func configure(with item: DisplayableChannel) {
        self.content.configure(with: item)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 60)
        return layoutAttributes
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentItem = nil
        self.content.stackedAvatarView.reset()
        self.content.label.text = nil 
    }
}
