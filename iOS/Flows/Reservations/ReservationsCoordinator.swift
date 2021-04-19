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
            self.presentShare(for: reservation)
        }
    }

    private func presentShare(for reservation: Reservation) {
        let ac = UIActivityViewController(activityItems: [reservation], applicationActivities: nil)
        ac.completionWithItemsHandler = { activityType, completed, items, error in
            if completed {
                self.showAlert()
            }
        }

        let exclusions: [UIActivity.ActivityType] = [.postToFacebook, .postToTwitter, .postToWeibo, .mail, .print, .assignToContact, .saveToCameraRoll, .addToReadingList, .postToFlickr, .postToVimeo, .postToTencentWeibo, .openInIBooks, .markupAsPDF, .airDrop]

        ac.excludedActivityTypes = exclusions

        self.reservationsVC.present(ac, animated: true, completion: nil)
    }

    private func showAlert() {
        let alert = UIAlertController(title: "Sent!",
                                      message: "Your RSVP has been sent. As soon as someone accepts using your link, a conversation will be created between the two of you.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }
}
