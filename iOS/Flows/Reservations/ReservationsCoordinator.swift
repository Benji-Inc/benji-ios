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
    private lazy var contactPicker = ContactPickerViewController()
    private lazy var messageComposer = MessageComposerViewController()

    init(reservation: Reservation,
         router: Router,
         deepLink: DeepLinkable?) {

        self.reservation = reservation
        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        if let _ = self.reservation.metadata {
            self.presentContacts()
            //self.presentShare()
        } else {
            self.reservation.prepareMetaData(andUpdate: [])
                .observeValue { [unowned self] (_) in
                    self.presentContacts()
                    //self.presentShare()
                }
        }
    }

    private func presentContacts() {
        self.contactPicker.delegate = self
        self.contactPicker.displayedPropertyKeys = [CNContactGivenNameKey, CNContactPhoneNumbersKey]
        self.router.navController.present(self.contactPicker, animated: true)
    }

    private func presentShare() {
        runMain {
            let ac = UIActivityViewController(activityItems: [self.reservation], applicationActivities: nil)
            ac.completionWithItemsHandler = { activityType, completed, items, error in
                self.showAlert()
            }
            self.router.navController.present(ac, animated: true)
        }
    }

    private func showAlert() {
        let alert = UIAlertController(title: "RSVP Sent",
                                      message: "Your invation has been sent. As soon as someone accepts, using your link, a conversation will be created between the two of you.",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .cancel) { (_) in
            self.finishFlow(with: ())
        }

        alert.addAction(ok)

        self.router.navController.present(alert, animated: true, completion: nil)
    }
}

extension ReservationsCoordinator: CNContactPickerDelegate {

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        self.contactPicker.dismiss(animated: true) {
            self.sendText(to: contact)
        }
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        self.contactPicker.dismissHandlers.append { [unowned self] in
            self.finishFlow(with: ())
        }
    }

    private func sendText(to contact: CNContact) {

        let userName = contact.givenName

        if let phoneString = contact.findBestPhoneNumber().phone?.stringValue {
            // Configure the fields of the interface.
            self.messageComposer.recipients = [phoneString]
            self.messageComposer.body = self.reservation.message
        }

        print(userName)

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
        case .cancelled:
            break
        case .sent:
            break
        case .failed:
            break
        @unknown default:
            break
        }
    }
}

private class ContactPickerViewController: CNContactPickerViewController, Dismissable {
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
