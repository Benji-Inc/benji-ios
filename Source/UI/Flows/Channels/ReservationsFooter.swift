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
    var didSelectReservation: ((Reservation, String) -> Void)? = nil
    var reservations: [Reservation] = []

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

        self.reservationsButton.didSelect = { [unowned self] in
            guard let reservation = self.reservations.first(where: { (reservation) -> Bool in
                return !reservation.isClaimed
            }) else { return }

            self.prepare(reservation: reservation)
        }
    }

    func configure() {
        self.getReservations()
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.reservationsButton.setSize(with: self.width - 16)
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

                self.reservations = reservations

                self.layoutNow()
        }
    }

    func prepare(reservation: Reservation) {
        self.reservationsButton.isLoading = true
        let channelId = UUID().uuidString
        reservation.prepareMetaData(with: channelId)
            .observeValue { (_) in
                self.didSelectReservation?(reservation, channelId)
                runMain {
                    self.reservationsButton.isLoading = false
                }
        }
    }
}
