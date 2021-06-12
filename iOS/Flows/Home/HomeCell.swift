//
//  HomeCell.swift
//  Ours
//
//  Created by Benji Dodgson on 6/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class HomeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = HomeItem
    var currentItem: HomeItem?

    func configure(with item: HomeItem) {
        self.contentView.set(backgroundColor: .background3)
    }

    override func layoutSubviews() {
        super.layoutSubviews()


    }
}
