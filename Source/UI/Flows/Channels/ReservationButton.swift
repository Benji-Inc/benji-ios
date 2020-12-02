//
//  ReservationButton.swift
//  Benji
//
//  Created by Benji Dodgson on 12/2/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationButton: LoadingButton {

    override func initializeSubviews() {
        super.initializeSubviews()
        guard let user = User.current() else { return }
        
        Reservation.getReservations(for: user)
            .observeValue { [weak self] (reservations) in
                guard let `self` = self else { return }
                //self.layout(reservations: Array.init(reservations.prefix(3)))
        }
    }
}
