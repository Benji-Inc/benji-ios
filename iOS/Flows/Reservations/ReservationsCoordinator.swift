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

class ReservationsCoordinator: Coordinator<Void> {

    let reservation: Reservation
    private lazy var messageComposer = MessageComposerViewController()

    init(reservation: Reservation,
         router: Router,
         deepLink: DeepLinkable?) {

        self.reservation = reservation
        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        self.sendText()
    }

    private func showAlert() {
        let alert = UIAlertController(title: "RSVP Sent",
                                      message: "Your RSVP has been sent. As soon as someone accepts, using your link, a conversation will be created between the two of you.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }

    private func sendText() {

        self.messageComposer.body = self.reservation.message
        self.messageComposer.messageComposeDelegate = self

        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.router.navController.present(self.messageComposer, animated: true, completion: nil)
        }
    }
}

extension ReservationsCoordinator: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled, .failed:
            self.messageComposer.dismiss(animated: true) {
                self.finishFlow(with: ())
            }
        case .sent:
            self.messageComposer.dismiss(animated: true) {
                self.showAlert()
            }
        @unknown default:
            break
        }
    }
}

private class MessageComposerViewController: MFMessageComposeViewController, Dismissable {
    var dismissHandlers: [() -> Void] = []

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler()
            }
        }
    }
}
