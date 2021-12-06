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

    let colorView = View()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.colorView)
        self.colorView.layer.cornerRadius = 5
    }

    func configure(with item: CIColor) {
        self.colorView.backgroundColor = UIColor(ciColor: item)
        self.colorView.alpha = 0.5
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.colorView.squaredSize = self.contentView.height
        self.colorView.centerOnXAndY()
    }

    override func update(isSelected: Bool) {
        self.colorView.alpha = isSelected ? 1.0 : 0.5
    }
}
