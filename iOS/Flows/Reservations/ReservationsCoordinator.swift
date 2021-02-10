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
    private var selectedContact: CNContact?
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
            ContactsManger.shared.searchForContact(with: .identifier(contactId))
                .mainSink { (result) in
                    switch result {
                    case .success(let contacts):
                        if let first = contacts.first {
                            self.findUser(for: first, sendReminder: true)
                        } else {
                            self.showIntroAlert()
                        }
                    case .error(_):
                        self.showIntroAlert()
                    }
                }.store(in: &self.cancellables)
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

    private func showSentAlert(for avatar: Avatar) {
        let message = LocalizedString(id: "", arguments: [avatar.fullName], default: "Your RSVP has been sent too @(name). As soon as they accept, a conversation will be created between the two of you.")
        let text = localized(message)
        let alert = UIAlertController(title: "RSVP Sent",
                                      message: text,
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }

    private func sendText(with message: String?, phone: String) {

        self.messageComposer.recipients = [phone]
        self.messageComposer.body = message
        self.messageComposer.messageComposeDelegate = self

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
                if let contact = self.selectedContact {
                    self.showSentAlert(for: contact)
                }
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
        self.selectedContact = contact
        self.findUser(for: contact, sendReminder: false)
    }

    func findUser(for contact: CNContact, sendReminder: Bool) {
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
                        if sendReminder {
                            self.sendText(with: "A reminder message", phone: phone)
                        } else {
                            self.sendText(with: self.reservation.message, phone: phone)
                        }
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
                self.showSentAlert(for: user)
            }).store(in: &self.cancellables)
    }
}
