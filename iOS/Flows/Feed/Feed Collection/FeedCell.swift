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

    func configure(with item: FakeItem) {
        self.contentView.set(backgroundColor: item.color)
    }
}
