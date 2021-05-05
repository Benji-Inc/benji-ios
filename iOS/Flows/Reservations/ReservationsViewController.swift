//
//  ReservationsViewController.swift
//  Ours
//
//  Created by Benji Dodgson on 4/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ReservationsViewController: NavigationBarViewController {

    let button = Button()
    let contactsButton = Button()

    var didSelectShowContacts: CompletionOptional = nil
    var didSelectReservation: ((Reservation) -> Void)? = nil

    private(set) var reservations: [Reservation] = []

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.button)
        self.button.set(style: .normal(color: .purple, text: "Share"))
        self.button.didSelect { [unowned self] in
            if let first = self.reservations.first(where: { reservation in
                reservation.contactId.isNil
            }) {
                self.didSelect(reservation: first)
            }
        }

        self.view.addSubview(self.contactsButton)
        self.contactsButton.set(style: .normal(color: .lightPurple, text: "Invite Contact"))
        self.contactsButton.didSelect { [unowned self] in
            self.didSelectShowContacts?()
        }
        
        self.loadUnclaimedReservations()
    }

    override func viewDidLayoutSubviews() {

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.pinToSafeArea(.bottom, padding: Theme.contentOffset)

        self.contactsButton.setSize(with: self.view.width)
        self.contactsButton.centerOnX()
        self.contactsButton.match(.bottom, to: .top, of: self.button, offset: -10)

        super.viewDidLayoutSubviews()
    }

    private func loadUnclaimedReservations() {
        guard let query = Reservation.query() else { return }

        button.handleEvent(status: .loading)
        query.whereKey(ReservationKey.createdBy.rawValue, equalTo: User.current()!)
        query.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
        query.findObjectsInBackground { objects, error in
            if let reservations = objects as? [Reservation] {
                self.button.handleEvent(status: .complete)
                self.show(reservations: reservations)
            }
        }
    }

    override func getTitle() -> Localized {
        return "Friends don't send, they swipe."
    }

    override func getDescription() -> Localized {
        return "Our's is an exclusive community that cares about quality over quantity when it comes to its users, so invite the people you are most social with. (iOS only)"
    }

    override func shouldShowBackButton() -> Bool {
        return false
    }

    private func show(reservations: [Reservation]) {
        self.reservations = reservations
        self.updateNavigationBar()
    }

    private func didSelect(reservation: Reservation) {
        self.button.handleEvent(status: .loading)
        reservation.prepareMetaData(andUpdate: [])
            .mainSink(receiveValue: { (_) in
                self.button.handleEvent(status: .complete)
                self.didSelectReservation?(reservation)
            }, receiveCompletion: { (_) in }).store(in: &self.cancellables)
    }
}
