//
//  ConversationCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = Conversation

    var currentItem: Conversation?

    private let content = ConversationContentView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.content)
        self.content.set(backgroundColor: .purple)
    }

    func configure(with item: Conversation) {
        self.content.configure(with: item)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes)
    -> UICollectionViewLayoutAttributes {
        
        layoutAttributes.size = CGSize(width: layoutAttributes.size.width, height: 60)
        return layoutAttributes
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
        self.content.roundCorners()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentItem = nil
    }
}
