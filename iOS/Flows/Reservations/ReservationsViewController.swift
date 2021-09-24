//
//  ReservationsViewController.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class ReservationsViewController: NavigationBarViewController {

    let contactsButton = Button()

    var didSelectShowContacts: CompletionOptional = nil

    private(set) var reservations: [Reservation] = []

    override func initializeViews() {
        super.initializeViews()

        self.view.addSubview(self.contactsButton)
        self.contactsButton.set(style: .normal(color: .purple, text: "Invite Contact"))
        self.contactsButton.didSelect { [unowned self] in
            self.didSelectShowContacts?()
        }

//        Task {
//            await self.loadUnclaimedReservations()
//        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.contactsButton.setSize(with: self.view.width)
        self.contactsButton.centerOnX()
        self.contactsButton.pinToSafeArea(.bottom, padding: Theme.contentOffset)
    }

//    @MainActor
//    private func loadUnclaimedReservations() async {
//        guard let query = Reservation.query() else { return }
//
//        await self.contactsButton.handleEvent(status: .loading)
//
//        query.whereKey(ReservationKey.createdBy.rawValue, equalTo: User.current()!)
//        query.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
//        do {
//            let objects = try await query.findObjectsInBackground()
//            await self.contactsButton.handleEvent(status: .complete)
//            if let reservations = objects as? [Reservation] {
//                self.show(reservations: reservations)
//            }
//        } catch {
//            logDebug(error)
//        }
//    }

    override func getTitle() -> Localized {
        return "Friends don't send, they swipe."
    }

    override func getDescription() -> Localized {
        return "Jibber is an exclusive community that cares about quality over quantity, especially with its users, so invite the people you are most social with. (iOS only)"
    }

    override func shouldShowBackButton() -> Bool {
        return false
    }

//    private func show(reservations: [Reservation]) {
//        self.reservations = reservations
//        self.updateNavigationBar()
//    }

//    private func didSelect(reservation: Reservation) {
//        Task {
//            do {
//                await self.contactsButton.handleEvent(status: .loading)
//                try await reservation.prepareMetadata(andUpdate: [])
//
//                await self.contactsButton.handleEvent(status: .complete)
//                self.didSelectReservation?(reservation)
//            } catch {
//                await self.contactsButton.handleEvent(status: .error(error.localizedDescription))
//            }
//        }
//    }
}
