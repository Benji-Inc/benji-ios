//
//  ReservationCell.swift
//  Ours
//
//  Created by Benji Dodgson on 1/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationCell: CollectionViewManagerCell {

    let button = Button()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.contentView.addSubview(self.button)
    }

    func configure(with reservation: Reservation) {

        if let contactId = reservation.contactId {

        } else {
            self.button.set(style: .normal(color: .purple, text: "Send RSVP"))
        }

        self.contentView.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.button.width = self.contentView.width * 0.95
        self.button.expandToSuperviewHeight()
        self.button.centerOnX()
    }
}
