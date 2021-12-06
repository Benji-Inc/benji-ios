//
//  ColorCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ColorCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = CIColor

    var currentItem: CIColor?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.layer.cornerRadius = 5
    }

    func configure(with item: CIColor) {
        self.contentView.backgroundColor = UIColor(ciColor: item)
    }
}
