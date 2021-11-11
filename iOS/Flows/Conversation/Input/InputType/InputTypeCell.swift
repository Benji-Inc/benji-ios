//
//  InputTypeCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class InputTypeCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = InputType

    var currentItem: InputType?

    private let imageView = UIImageView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.imageView)
        self.imageView.alpha = 0.5
        self.imageView.tintColor = Color.gray.color
        self.imageView.contentMode = .scaleAspectFit
    }

    func configure(with item: InputType) {
        self.currentItem = item
        self.imageView.image = item.image
    }

    override func update(isSelected: Bool) {
        super.update(isSelected: isSelected)

        self.imageView.alpha = isSelected ? 1.0 : 0.5
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = self.contentView.height * 0.8
        self.imageView.centerOnXAndY()
    }
}
