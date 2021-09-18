//
//  UserCell.swift
//  UserCell
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class UserCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = User

    var currentItem: User?

    var imageView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
    }

    func configure(with item: User) {
        self.imageView.displayable = item
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.setSize(for: self.height)
        self.imageView.centerOnXAndY()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentItem = nil
    }
}
