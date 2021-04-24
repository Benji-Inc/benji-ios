//
//  FeedCell.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = User

    var currentItem: User?

    private let avatarView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.avatarView.alpha = 0.8
    }

    func configure(with item: User) {
        item.retrieveDataIfNeeded()
            .mainSink(receivedResult: { result in
                switch result {
                case .success(let owner):
                    self.avatarView.set(avatar: owner)
                case .error(_):
                    break
                }
            }).store(in: &self.cancellables)
    }

    override func update(isSelected: Bool) {
        self.avatarView.alpha = isSelected ? 1.0 : 0.6
        self.avatarView.borderColor = isSelected ? .purple : .background2
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.height)
        self.avatarView.centerOnXAndY()
    }
}
