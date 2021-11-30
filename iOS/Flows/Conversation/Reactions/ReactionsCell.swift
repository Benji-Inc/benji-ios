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
    typealias ItemType = Set<ChatMessageReaction>

    var currentItem: Set<ChatMessageReaction>?

    let container = View()
    let emojiLabel = Label(font: .regular)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.container)
        self.container.addSubview(self.emojiLabel)
        self.container.backgroundColor = Color.white.color.withAlphaComponent(0.1)
        self.container.layer.cornerRadius = 5
        self.container.layer.borderColor = Color.darkGray.color.withAlphaComponent(0.3).cgColor
        self.container.layer.borderWidth = 0.25
    }

    func configure(with item: Set<ChatMessageReaction>) {
        guard let first = item.first, let type = ReactionType(rawValue: first.type.rawValue) else { return }
        let text = type.rawValue + "\(item.count)"
        self.emojiLabel.setText(text)
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.emojiLabel.setSize(withWidth: self.width)
        self.emojiLabel.centerOnXAndY()
    }
}
