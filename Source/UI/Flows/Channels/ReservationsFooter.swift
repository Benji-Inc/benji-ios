//
//  ReservationsFooter.swift
//  Benji
//
//  Created by Benji Dodgson on 5/26/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ReservationsFooter: UICollectionReusableView {

    let reservationsButton = LoadingButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.addSubview(self.reservationsButton)
        self.reservationsButton.set(style: .normal(color: .purple, text: "Invite"))
    }

    func configure() {
        self.getReservations()
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.reservationsButton.setSize(with: self.width - 32)
        self.reservationsButton.centerOnXAndY()
    }

    private func getReservations() {
        guard let user = User.current() else { return }

        Reservation.getReservations(for: user)
            .observeValue { (reservations) in
                var numberOfUnclaimed: Int = 0

                reservations.forEach { (reservation) in
                    if !reservation.isClaimed {
                        numberOfUnclaimed += 1
                    }
                }

                var text = ""
                if numberOfUnclaimed == 0 {
                    text = "You have no reservations left."
                    //self.button.isHidden = true
                } else {
                    text = "You have \(String(numberOfUnclaimed)) left."
                    //self.button.isHidden = false
                }

                self.layoutNow()

                //self.label.set(text: text)
                //self.button.set(style: .normal(color: .lightPurple, text: "SHARE"))
        }
    }
}
