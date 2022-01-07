//
//  ReactionsCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ReactionsCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = ReactionSummary

    var currentItem: ReactionSummary?

    let container = BaseView()
    let emojiLabel = ThemeLabel(font: .reactionEmoji, textColor: .white)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.container)
        self.container.addSubview(self.emojiLabel)
        self.container.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.container.layer.cornerRadius = Theme.innerCornerRadius
        self.container.layer.borderColor = ThemeColor.D6withAlpha.color.cgColor
        self.container.layer.borderWidth = 0.25
    }

    func configure(with item: ReactionSummary) {
        let text = item.type.emoji + " \(item.count)"
        self.emojiLabel.setText(text)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.container.expandToSuperviewSize()

        self.emojiLabel.setSize(withWidth: self.width)
        self.emojiLabel.centerOnXAndY()
    }
}
