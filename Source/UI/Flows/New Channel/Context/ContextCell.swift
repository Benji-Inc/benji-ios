//
//  ContextCell.swift
//  Benji
//
//  Created by Benji Dodgson on 4/6/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ContextCell: UICollectionViewCell, ManageableCell {
    typealias ItemType = ConversationContext

    var onLongPress: (() -> Void)?

    private let button = Button()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeViews() {
        self.contentView.addSubview(self.button)
    }

    func configure(with item: ConversationContext?) {
        guard let context = item else { return }

        self.button.set(style: .normal(color: context.color, text: context.title))
    }

    func collectionViewManagerWillDisplay() {}
    func collectionViewManagerDidEndDisplaying() {}

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.expandToSuperviewSize()
    }
}
