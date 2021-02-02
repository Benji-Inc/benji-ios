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

class ReservationsCoordinator: Coordinator<Void> {

    let reservation: Reservation
    private lazy var messageComposer = MessageComposerViewController()
    lazy var contactPicker = CNContactPickerViewController()
    private var cancellables = Set<AnyCancellable>()

    init(reservation: Reservation,
         router: Router,
         deepLink: DeepLinkable?) {

        self.reservation = reservation
        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        if let contactId = self.reservation.contactId {
            //Find and remind contact
        } else {
            self.showIntroAlert()
        }
    }

    private func showIntroAlert() {
        let alert = UIAlertController(title: "Choose wisely",
                                      message: "Ours is designed to work best with the people you communicate with the most. Ours is currently only available on iOS.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            alert.dismiss(animated: true) {
                self.showContacts()
            }
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }

    private func showContacts() {
        self.contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey]
        self.contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        self.contactPicker.delegate = self
        self.router.navController.present(self.contactPicker, animated: true, completion: nil)
    }

    private func showSentAlert(for contact: CNContact) {
        let alert = UIAlertController(title: "RSVP Sent",
                                      message: "Your RSVP has been sent. As soon as someone accepts, using your link, a conversation will be created between the two of you.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }

    private func sendText(for phone: String) {

        self.messageComposer.recipients = [phone]
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
                //self.showSentAlert()
            }
        @unknown default:
            break
        }
    }
}

private class MessageComposerViewController: MFMessageComposeViewController, Dismissable {
    var dismissHandlers: [DismissHandler] = []

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if self.isBeingClosed {
            self.dismissHandlers.forEach { (dismissHandler) in
                dismissHandler.handler?()
            }
        }
    }
}

extension ReservationsCoordinator: CNContactPickerDelegate {

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true) {
            self.finishFlow(with: ())
        }
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        // Search for user with phone number
        guard let query = User.query(), let phone = contact.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers() else { return }
        query.whereKey("phoneNumber", contains: phone)
        query.getFirstObjectInBackground { (object, error) in
            if let user = object as? User {
                self.showReservationAlert(for: user)
            } else {
                self.reservation.contactId = contact.identifier
                self.reservation.saveLocalThenServer()
                    .mainSink { (updatedReservation) in
                        self.sendText(for: phone)
                    }.store(in: &self.cancellables)
            }
        }
    }

    func showReservationAlert(for user: User) {
        let title = LocalizedString(id: "", arguments: [user.fullName], default: "Connect with @(name)?")
        let titleText = localized(title)

        let body = LocalizedString(id: "", arguments: [user.fullName], default: "@(name) has an account. Tap OK to send the request.")
        let bodyText = localized(body)
        let alert = UIAlertController(title: titleText,
                                      message: bodyText,
                                      preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.createConnection(with: user)
        }

        alert.addAction(cancel)
        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }

    func createConnection(with user: User) {
        CreateConnection(to: user).makeRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink(receiveValue: { (_) in
                //self.showSentAlert()
            }).store(in: &self.cancellables)
    }
}

extension CNContact {
    func findBestPhoneNumber() -> (phone: CNPhoneNumber?, label: String?) {

        var bestPair: (CNPhoneNumber?, String?) = (nil, nil)
        let prioritizedLabels = ["iPhone",
                                 "_$!<Mobile>!$_",
                                 "_$!<Main>!$_",
                                 "_$!<Home>!$_",
                                 "_$!<Work>!$_"]

        // Look for a number with a priority label first
        for label in prioritizedLabels {
            for entry: CNLabeledValue in self.phoneNumbers {
                if entry.label == label {
                    let readableLabel = self.readable(label)
                    bestPair = (entry.value, readableLabel)
                    break
                }
            }
        }

        // Then look to see if there are any numbers with custom labels if we
        // didn't find a priority label
        if bestPair.0 == nil || bestPair.1 == nil {
            let lowPriority = self.phoneNumbers.filter { entry in
                if let label = entry.label {
                    return !prioritizedLabels.contains(label)
                } else {
                    return false
                }
            }

            if let entry = lowPriority.first, let label = entry.label {
                let readableLabel = self.readable(label)
                bestPair = (entry.value, readableLabel)
            }
        }

        if bestPair.0.isNil {
            bestPair = (self.phoneNumbers.first?.value, nil)
        }

        return bestPair
    }

    func readable(_ label: String) -> String {
        let cleanLabel: String

        switch label {
        case _ where label == "iPhone":         cleanLabel = "iPhone"
        case _ where label == "_$!<Mobile>!$_": cleanLabel = "Mobile"
        case _ where label == "_$!<Main>!$_":   cleanLabel = "Main"
        case _ where label == "_$!<Home>!$_":   cleanLabel = "Home"
        case _ where label == "_$!<Work>!$_":   cleanLabel = "Work"
        default:                                cleanLabel = label
        }

        return cleanLabel
    }
}
