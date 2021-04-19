//
//  ReservationsCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 5/30/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ContactsUI
import MessageUI
import TMROLocalization
import Combine

class ReservationsCoordinator: PresentableCoordinator<Void> {

    lazy var reservationsVC = ReservationsViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.reservationsVC
    }

    override func start() {
        super.start()

        self.reservationsVC.didSelectReservation = { [unowned self] reservation in 

        }

    }
}

extension ReservationsCoordinator: CNContactPickerDelegate {

    func findUser(for contact: CNContact) {
        // Search for user with phone number
        guard let query = User.query(), let phone = contact.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers() else { return }
        query.whereKey("phoneNumber", contains: phone)
        query.getFirstObjectInBackground { [unowned self] (object, error) in
//            if let user = object as? User {
//                self.showReservationAlert(for: user)
//            } else if self.reservation.contactId == contact.identifier {
//                self.sendText(with: self.reservation.reminderMessage, phone: phone)
//            } else {
//                self.reservation.contactId = contact.identifier
//                self.reservation.saveLocalThenServer()
//                    .mainSink { (updatedReservation) in
//                        self.sendText(with: self.reservation.message, phone: phone)
//                    }.store(in: &self.cancellables)
//            }
        }
    }
}
