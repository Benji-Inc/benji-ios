//
//  InviteCell.swift
//  Benji
//
//  Created by Benji Dodgson on 2/8/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class PendingConnectionCell: UICollectionViewCell {

    var onLongPress: (() -> Void)?

    let content = InviteableContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeSubviews() {
        self.contentView.addSubview(self.content)
    }

    func configure(with item: Connection) {
        self.content.configure(with: .connection(item))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()
    }
}
