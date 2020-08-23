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

        self.contentView.addSubview(self.imageView)
        self.contentView.set(backgroundColor: .red)
    }

    override func configure(with message: Messageable) {
        super.configure(with: message)

        guard let displayable = message.kind as? ImageDisplayable else { return }

        self.imageView.displayable = displayable
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.expandToSuperviewSize()
    }
}
