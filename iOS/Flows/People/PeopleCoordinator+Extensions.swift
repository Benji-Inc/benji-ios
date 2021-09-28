//
//  PeopleCoordinator+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/28/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ContactsUI
import MessageUI
import TMROLocalization

extension PeopleCoordinator {
    
    private func showSentToast() {
        ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: UIImage(systemName: "envelope")!, title: "RSVP Sent", description: "Your RSVP has been sent. As soon as someone accepts using your link, a conversation will be created between the two of you.", deepLink: nil))
    }

    private func showContacts() {
        self.inviteIndex = 0
        self.contactsVC.delegate = self
        self.router.present(self.contactsVC, source: self.peopleVC)
    }

    private func showSentAlert(for avatar: Avatar) {
        let text = LocalizedString(id: "", arguments: [avatar.fullName], default: "Your RSVP has been sent to @(name). As soon as they accept, a conversation will be created between the two of you.")
        ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: avatar, title: "RSVP Sent", description: text, deepLink: nil))
    }

    private func sendText(with message: String?, phone: String) {
        self.messageComposer = MessageComposerViewController()
        self.messageComposer?.recipients = [phone]
        self.messageComposer?.body = message
        self.messageComposer?.messageComposeDelegate = self

        if MFMessageComposeViewController.canSendText() {
            self.router.topmostViewController.present(self.messageComposer!, animated: true, completion: nil)
        }
    }

    func updateInvitation() {
        if let contact = self.contactsToInvite[safe: self.inviteIndex],
           let rsvp = self.reservations[safe: self.inviteIndex] {
            self.invite(contact: contact, with: rsvp)
        }

        self.inviteIndex += 1
    }

    func invite(contact: Contact, with reservation: Reservation) {
        Task {
            await self.peopleVC.showLoading(for: contact)
            // Show loading on screen
            //await self.reservationsVC.contactsButton.handleEvent(status: .loading)
            await self.findUser(with: contact.cnContact, for: reservation)
            //await self.reservationsVC.contactsButton.handleEvent(status: .complete)
        }
    }

    func findUser(with contact: CNContact, for reservation: Reservation) async {
        // Search for user with phone number
        guard let phone = contact.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers() else { return }

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

extension PeopleCoordinator: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled, .failed:
            controller.dismiss(animated: true) {
                self.updateInvitation()
            }
        case .sent:
            controller.dismiss(animated: true) {
                if let contact = self.selectedContact {
                    self.showSentAlert(for: contact)
                    self.updateInvitation()
                }
            }
        @unknown default:
            break
        }
    }
}
