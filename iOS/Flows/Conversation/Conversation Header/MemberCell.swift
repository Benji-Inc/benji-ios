//
//  MemberCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class MemberCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = AnyHashableDisplayable

    var currentItem: AnyHashableDisplayable?

    let avatarView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
    }

    func configure(with item: AnyHashableDisplayable) {
        self.avatarView.set(avatar: item.value)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.contentView.height)
        self.avatarView.centerOnXAndY()
    }
}
