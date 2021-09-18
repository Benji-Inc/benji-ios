//
//  CirclesCell.swift
//  CirclesCell
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleGroupCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = CircleGroup

    var currentItem: CircleGroup?

    override func initializeSubviews() {
        super.initializeSubviews()

    }

    func configure(with item: CircleGroup) {
    }

    override func layoutSubviews() {
        super.layoutSubviews()


    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.currentItem = nil
    }
}
