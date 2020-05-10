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
    func invitesView(_ controller: InvitesViewController, didSelect reservation: Reservation) {

        let ac = UIActivityViewController(activityItems: [reservation], applicationActivities: nil)
        self.router.navController.present(ac, animated: true) {
            // Do something?
        }
    }
}

