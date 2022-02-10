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
import Localization

extension PeopleCoordinator {

    private func showSentTextToast(for avatar: Avatar) {
        let text = LocalizedString(id: "", arguments: [avatar.fullName], default: "Your RSVP has been sent to @(name). As soon as they accept, a conversation will be created between the two of you.")
        Task {
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: Lorem.randomString(), displayable: avatar, title: "RSVP Sent", description: text, deepLink: nil))
        }.add(to: self.taskPool)
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

    @MainActor
    func updateInvitation() async {

        if let person = self.peopleToInvite[safe: self.inviteIndex] {
            if let connection = try? await person.connection?.retrieveDataIfNeeded(),
                connection.status == .accepted {
            
                self.invitedPeople.append(person)
                self.inviteIndex += 1

                await self.updateInvitation()
            } else if let rsvp = self.peopleNavController.peopleVC.reservations[safe: self.inviteIndex] {
                self.invite(person: person, with: rsvp)
            } else {
                await self.finish()
            }
        } else {
            await self.finish()
        }

        self.inviteIndex += 1
    }
    
    @MainActor
    func finish() async {
        await self.peopleNavController.peopleVC.finishInviting()
        self.finishFlow(with: self.invitedPeople)
    }

    func invite(person: Person, with reservation: Reservation) {
        Task {
            await self.peopleNavController.peopleVC.showLoading(for: person)
            await self.findUser(with: person.cnContact, for: reservation)
        }.add(to: self.taskPool)
    }

    func findUser(with contact: CNContact?, for reservation: Reservation) async {
        // Search for user with phone number
        guard let phone = contact?.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers() else { return }

        reservation.conversationCid = self.selectedConversationCID?.description

        do {
            async let matchingUser = User.getFirstObject(where: "phoneNumber", contains: phone)
            // Ensure that the reservation metadata is prepared before we show the reservation
            try await reservation.prepareMetadata(andUpdate: [])
            try await reservation.saveLocalThenServer()
            try await self.showConnectionAlert(for: matchingUser)
        } catch {
            if reservation.contactId == contact?.identifier {
                self.sendText(with: reservation.reminderMessage, phone: phone)
            } else {
                reservation.contactId = contact?.identifier
                _ = try? await reservation.saveLocalThenServer()
                self.sendText(with: reservation.message, phone: phone)
            }
        }
    }

    func showConnectionAlert(for user: User) {
        let title = LocalizedString(id: "", arguments: [user.fullName], default: "Connect with @(name)?")
        let titleText = localized(title)

        let body = LocalizedString(id: "", arguments: [user.fullName], default: "@(name) has an account. Tap OK to send the request. (This will NOT consume one of your RSVPs)")
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
                let value = try await CreateConnection(to: user).makeRequest(andUpdate: [], viewsToIgnore: [])
                if let connection = value as? Connection {
                    let person = Person(withConnection: connection)
                    self.invitedPeople.append(person)
                }
                await self.updateInvitation()
            } catch {
                print(error)
            }
        }.add(to: self.taskPool)
    }
}

extension PeopleCoordinator: MFMessageComposeViewControllerDelegate {

    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled, .failed:
            controller.dismiss(animated: true) {
                Task {
                    await self.updateInvitation()
                }.add(to: self.taskPool)
            }
        case .sent:
            controller.dismiss(animated: true) {
                if let phone = controller.recipients?.first, let person = self.peopleToInvite.first(where: { person in
                    if let c = person.cnContact, let phoneString = c.findBestPhoneNumber().phone?.stringValue.removeAllNonNumbers(),
                        phone == phoneString {
                        return true
                    } else {
                        return false
                    }
                }), let contact = person.cnContact {
                    let person = Person(withContact: contact)
                    self.invitedPeople.append(person)
                    self.showSentTextToast(for: person)
                }
                
                Task {
                    await self.updateInvitation()
                }.add(to: self.taskPool)
            }
        @unknown default:
            break
        }
    }
}
