//
//  ReservationCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationCell: NoticeCell {

    let label = Label(font: .mediumBold)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.set(backgroundColor: .lightGray)
        self.contentView.addSubview(self.label)

        self.label.textAlignment = .center
    }

    override func configure(with item: SystemNotice) {
        super.configure(with: item)

        self.label.setText(item.body)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.label.setSize(withWidth: self.contentView.width - Theme.contentOffset)
        self.label.centerOnXAndY()
    }
}
