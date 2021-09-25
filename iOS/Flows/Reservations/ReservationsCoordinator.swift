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
    private var selectedContact: CNContact?
    private var selectedReservation: Reservation?
    private lazy var messageComposer = MessageComposerViewController()

    private lazy var contactsVC = ContactsViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.reservationsVC
    }

    override func start() {
        super.start()

        self.reservationsVC.didSelectShowContacts = { [unowned self] in
            self.showContacts()
        }
    }

    private func showSentToast() {
        ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: UIImage(systemName: "envelope")!, title: "RSVP Sent", description: "Your RSVP has been sent. As soon as someone accepts using your link, a conversation will be created between the two of you.", deepLink: nil))
    }

    private func showContacts() {
        self.contactsVC.delegate = self
        self.router.present(self.contactsVC, source: self.reservationsVC)
    }

    private func showSentAlert(for avatar: Avatar) {
        let text = LocalizedString(id: "", arguments: [avatar.fullName], default: "Your RSVP has been sent to @(name). As soon as they accept, a conversation will be created between the two of you.")
        ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: avatar, title: "RSVP Sent", description: text, deepLink: nil))
    }

    private func sendText(with message: String?, phone: String) {
        self.messageComposer.recipients = [phone]
        self.messageComposer.body = message
        self.messageComposer.messageComposeDelegate = self

        if MFMessageComposeViewController.canSendText() {
            self.router.topmostViewController.present(self.messageComposer, animated: true, completion: nil)
        }
    }
}

extension ReservationsCoordinator: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled, .failed:
            self.messageComposer.dismiss(animated: true)
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

extension ReservationsCoordinator: PeopleViewControllerDelegate {

    nonisolated func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType]) {

    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.selectedContact = contact

        // Find the RSVP that has been used for the contact before
        self.selectedReservation = self.reservationsVC.reservations.first(where: { reservation in
            reservation.contactId == contact.identifier
        })

        if self.selectedReservation.isNil {
            self.selectedReservation = self.reservationsVC.reservations.first(where: { reservation in
                reservation.contactId.isNil
            })
        }

        if self.selectedReservation.isNil {
            self.selectedReservation = self.reservationsVC.reservations.first
        }

        picker.dismiss(animated: true) {
            Task {
                await self.reservationsVC.contactsButton.handleEvent(status: .loading)
                await self.findUser(for: contact)
                await self.reservationsVC.contactsButton.handleEvent(status: .complete)
            }
        }
    }

    func findUser(for contact: CNContact) async {
        // Search for user with phone number
        guard let phone = contact.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers(),
              let reservation = self.selectedReservation else {
                  return
              }
        
        do {
            async let matchingUser = User.getFirstObject(where: "phoneNumber", contains: phone)
            // Ensure that the reservation metadata is prepared before we show the reservation
            try await reservation.prepareMetadata(andUpdate: [])

            try await self.showReservationAlert(for: matchingUser)
        } catch {
            if reservation.contactId == contact.identifier {
                self.sendText(with: reservation.reminderMessage, phone: phone)
            } else {
                reservation.contactId = contact.identifier
                _ = try? await reservation.saveLocalThenServer()
                self.sendText(with: reservation.message, phone: phone)
            }
        }
    }

    func showReservationAlert(for user: User) {
        let title = LocalizedString(id: "", arguments: [user.fullName], default: "Connect with @(name)?")
        let titleText = localized(title)

        let body = LocalizedString(id: "", arguments: [user.fullName], default: "@(name) has an account. Tap OK to send the request. (This will NOT consume one of your RSVP's)")
        let bodyText = localized(body)
        let alert = UIAlertController(title: titleText,
                                      message: bodyText,
                                      preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in

        }

        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.createConnection(with: user)
        }

        alert.addAction(cancel)
        alert.addAction(ok)

        self.router.topmostViewController.present(alert, animated: true, completion: nil)
    }

    func createConnection(with user: User) {
        Task {
            do {
                try await CreateConnection(to: user).makeRequest(andUpdate: [], viewsToIgnore: [])
                self.showSentAlert(for: user)
            } catch {
                print(error)
            }
        }
    }
}
