//
//  ColorCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

class ColorCell: CollectionViewManagerCell, ManageableCell {

    typealias ItemType = CIColor

    var currentItem: CIColor?

    let colorView = View()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.colorView)
        self.colorView.layer.cornerRadius = 5
        self.colorView.layer.borderColor = Color.white.color.withAlphaComponent(0.0).cgColor
        self.colorView.layer.borderWidth = 3 
    }

    func configure(with item: CIColor) {
        self.colorView.backgroundColor = UIColor(ciColor: item)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.colorView.squaredSize = self.contentView.height
        self.colorView.centerOnXAndY()
    }

    override func update(isSelected: Bool) {
        UIView.animate(withDuration: Theme.AnimationDuration.fast.value) {
            self.colorView.layer.borderColor = isSelected ? Color.white.color.withAlphaComponent(1.0).cgColor : Color.white.color.withAlphaComponent(0.0).cgColor
        }
    }
}
