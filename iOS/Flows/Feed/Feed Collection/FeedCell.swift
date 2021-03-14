//
//  FeedCell.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class FeedCell: ManagerCell {
    typealias ItemType = Feed

    var currentItem: Feed?

    private let avatarView = AvatarView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.avatarView)
        self.avatarView.alpha = 0.8
    }

    func configure(with item: Feed) {
        item.owner?.retrieveDataIfNeeded()
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
        self.avatarView.alpha = isSelected ? 1.0 : 0.8
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.avatarView.setSize(for: self.height - Theme.contentOffset.doubled)
        self.avatarView.centerOnXAndY()
    }
}
