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

extension InvitesCoordinator: InvitesViewControllerDelegate {

    func invitesView(_ controller: InvitesViewController, didGetAuthorization status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            runMain {
                self.askForAuthorization(status: status)
            }
        case .authorized:
            runMain {
                self.invitesVC.loadItems()
            }
        @unknown default:
            runMain {
                self.askForAuthorization(status: status)
            }
        }
    }

    private func askForAuthorization(status: CNAuthorizationStatus) {

        let contactModal = ContactAuthorizationController(status: status)
        contactModal.onAuthorization = { (result) in
            switch result {
            case .denied:
                contactModal.dismiss(animated: true, completion: nil)
            case .authorized:
                contactModal.dismiss(animated: true) {
                    ContactsManager.shared.requestForAccess { [unowned self] (success, error) in
                        if success {
                            runMain {
                                self.invitesVC.loadItems()
                            }
                        }
                    }
                }
            }
        }

        self.router.present(contactModal, source: self.invitesVC)
    }

    func invitesView(_ controller: InvitesViewController, didSelect contacts: [CNContact]) {
        // go to invite coordinator
        let coordinator = InviteComposerCoordinator(router: self.router,
                                            deeplink: self.deepLink,
                                            contacts: contacts,
                                            source: controller)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            runMain {
                self.invitesVC.loadItems()
            }
        })
    }
}

