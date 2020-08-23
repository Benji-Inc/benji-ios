//
//  PhotoMessageCell.swift
//  Benji
//
//  Created by Benji Dodgson on 7/4/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PhotoMessageCell: BaseMessageCell {

    private let imageView = DisplayableImageView()

    override func initializeViews() {
        super.initializeViews()

        self.contentView.insertSubview(self.imageView, belowSubview: self.avatarView)
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        guard case MessageKind.photo(let item) = message.kind else { return }

        self.avatarView.set(avatar: message.avatar)
        self.imageView.displayable = item.image
        self.imageView.imageView.contentMode = .scaleAspectFill
        self.imageView.imageView.clipsToBounds = true
        self.imageView.layer.cornerRadius = 5
        self.imageView.layer.masksToBounds = true 
    }

    override func layoutContent(with attributes: ChannelCollectionViewLayoutAttributes) {
        super.layoutContent(with: attributes)

        self.imageView.frame = attributes.attributes.imageFrame
    }
}
