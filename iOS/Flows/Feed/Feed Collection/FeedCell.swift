//
//  FeedCell.swift
//  Ours
//
//  Created by Benji Dodgson on 3/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct FakeItem: Hashable {
    var identifier = UUID().uuidString
    var color: Color = .purple
}

class FeedCell: ManagerCell {
    typealias ItemType = FakeItem

    var currentItem: FakeItem?

    let someView = View()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.someView)
    }

    func configure(with item: FakeItem) {
        self.someView.set(backgroundColor: item.color)
    }

    override func update(isSelected: Bool) {
        self.someView.alpha = isSelected ? 0.5 : 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.someView.width = self.contentView.width - Theme.contentOffset.doubled
        self.someView.height = self.contentView.height - Theme.contentOffset.doubled

        self.someView.centerOnXAndY()
    }
}
