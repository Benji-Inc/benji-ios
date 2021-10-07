//
//  ReservationCell.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/7/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationCell: NoticeCell {

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.set(backgroundColor: .red)
    }

    override func configure(with item: SystemNotice) {
        super.configure(with: item)


    }
}
