//
//  LinkCell.swift
//  Ours
//
//  Created by Benji Dodgson on 6/4/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LinkCell: BaseMessageCell {

    private var cachedURL: URL?
    let imageView = LinkView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.insertSubview(self.imageView, belowSubview: self.avatarView)
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        guard case MessageKind.link(let link) = message.kind else { return }

        self.avatarView.set(avatar: message.avatar)
    }

    override func handleIsConsumed(for message: Messageable) {
        super.handleIsConsumed(for: message)

    }

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)

        self.imageView.frame = attributes.attributes.attachmentFrame
    }

    override func prepareForReuse() {
        super.prepareForReuse()

    }
}
