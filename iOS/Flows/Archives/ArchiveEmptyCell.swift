//
//  ArchiveEmptyCell.swift
//  Ours
//
//  Created by Benji Dodgson on 5/21/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct EmptyCellItem: Hashable {
    var identifier = UUID()
}

class ArchiveEmptyCell: CollectionViewManagerCell, ManageableCell {
    typealias ItemType = EmptyCellItem

    private let label = Label(font: .smallBold)

    var currentItem: EmptyCellItem?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.label)
        self.label.setTextColor(.background4)
        self.label.textAlignment = .center
        self.label.setText("Nothing to see here...")
    }

    func configure(with item: EmptyCellItem) {}

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.width)
        self.label.centerOnXAndY()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.reset()
    }
}
