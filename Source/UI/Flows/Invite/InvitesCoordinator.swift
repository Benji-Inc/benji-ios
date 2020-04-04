//
//  ContactsCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 2/7/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Contacts

class InvitesCoordinator: PresentableCoordinator<Void> {

    lazy var invitesVC = InvitesViewController(with: self)

    override func toPresentable() -> DismissableVC {
        return self.invitesVC
    }
}

extension InvitesCoordinator: ContactsViewControllerDelegate {

    func contactsView(_ controller: ContactsViewController, didGetAuthorization status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            runMain {
                self.askForAuthorization(status: status, source: controller)
            }
        case .authorized:
            controller.getContacts()
        @unknown default:
            runMain {
                self.askForAuthorization(status: status, source: controller)
            }
        }
    }

    private func askForAuthorization(status: CNAuthorizationStatus, source: ContactsViewController) {

        let contactModal = ContactAuthorizationController(status: status)
        contactModal.onAuthorization = { (result) in
            switch result {
            case .denied:
                contactModal.dismiss(animated: true, completion: nil)
            case .authorized:
                contactModal.dismiss(animated: true) {
                    source.getContacts()
                }
            }
        }

        self.router.present(contactModal, source: self.invitesVC)
    }
}

extension InvitesCoordinator: InvitesViewControllerDelegate {
    func invitesView(_ controller: InvitesViewController, didSelect contacts: [CNContact]) {
        // go to invite coordinator
        let coordinator = InviteComposerCoordinator(router: self.router,
                                            deeplink: self.deepLink,
                                            contacts: contacts,
                                            source: controller)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            //controller.reset()
        })
    }
}

