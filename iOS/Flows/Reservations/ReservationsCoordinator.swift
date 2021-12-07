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

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.reservationsVC
    }

    override func start() {
        super.start()

        self.reservationsVC.didSelectShowContacts = { [unowned self] in
            self.startPeopleFlow()
        }
    }

    func startPeopleFlow() {
        self.removeChild()
        let coordinator = PeopleCoordinator(includeConnections: false,
                                            conversationID: nil,
                                            router: self.router,
                                            deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: self.reservationsVC)
        }
        self.router.present(coordinator, source: self.reservationsVC)
    }
}
