//
//  PeopleCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Contacts

class PeopleCoordinator: PresentableCoordinator<Void> {

    lazy var peopleVC = PeopleViewController(includeConnections: self.includeConnections)

    var messageComposer: MessageComposerViewController?
    lazy var contactsVC = ContactsViewController()

    var selectedContact: CNContact?
    var reservations: [Reservation] = []
    var contactsToInvite: [Contact] = []
    var inviteIndex: Int = 0

    private let includeConnections: Bool
    private let conversation: Conversation?

    init(includeConnections: Bool = true,
         conversation: Conversation? = nil,
         router: Router,
         deepLink: DeepLinkable?) {

        self.conversation = conversation
        self.includeConnections = includeConnections
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.peopleVC
    }

    override func start() {
        super.start()

        self.peopleVC.delegate = self
    }
}

extension PeopleCoordinator: PeopleViewControllerDelegate {

    nonisolated func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType]) {

        Task.onMainActor {

            self.reservations = controller.reservations

            self.contactsToInvite = items.compactMap({ item in
                switch item {
                case .connection(_):
                    return nil
                case .contact(let contact):
                    return contact
                }
            })

            self.updateInvitation()
        }
    }
}

