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

class PeopleCoordinator: PresentableCoordinator<[Connection]> {
    lazy var peopleNavController = PeopleNavigationController()
    
    var messageComposer: MessageComposerViewController?
    lazy var contactsVC = ContactsViewController()

    var selectedContact: CNContact?
    var peopleToInvite: [Person] = []
    var inviteIndex: Int = 0
    let conversationID: ConversationId?

    private let includeConnections: Bool
    var selectedConnections: [Connection] = []

    init(includeConnections: Bool = true,
         conversationID: ConversationId?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.conversationID = conversationID
        self.includeConnections = includeConnections
        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> DismissableVC {
        return self.peopleNavController
    }

    override func start() {
        super.start()

        self.peopleNavController.peopleVC.delegate = self
    }
}

extension PeopleCoordinator: PeopleViewControllerDelegate {

    nonisolated func peopleView(_ controller: PeopleViewController, didSelect items: [PeopleCollectionViewDataSource.ItemType]) {
        
        Task.onMainActor {
            self.peopleNavController.prepareForInvitations()
            self.peopleToInvite = items.compactMap({ item in
                switch item {
                case .person(let person):
                    if let _ = person.cnContact {
                        return person
                    } else if let connection = person.connection {
                        self.selectedConnections.append(connection)
                    } else {
                        return nil
                    }
                }
                
                return nil
            })

            self.updateInvitation()
        }
    }
}

