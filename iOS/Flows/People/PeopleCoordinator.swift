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

class PeopleCoordinator: PresentableCoordinator<[Person]> {
    lazy var peopleNavController = PeopleNavigationController()
    
    var messageComposer: MessageComposerViewController?

    var peopleToInvite: [Person] = []
    var invitedPeople: [Person] = []
    
    var inviteIndex: Int = 0

    override func toPresentable() -> DismissableVC {
        return self.peopleNavController
    }

    override func start() {
        super.start()

        self.peopleNavController.peopleVC.delegate = self
    }
}

extension PeopleCoordinator: PeopleViewControllerDelegate {

    nonisolated func peopleView(_ controller: PeopleViewController,
                                didSelect items: [PeopleCollectionViewDataSource.ItemType]) {
        
        Task.onMainActor {
            self.peopleNavController.prepareForInvitations()
            self.updateInvitation()
        }
    }
}

