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

    var peopleToInvite: [Person] {
        return self.peopleNavController.peopleVC.selectedPeople
    }
    
    var invitedPeople: [Person] = []
    
    var inviteIndex: Int = 0
    
    var selectedConversationCID: ConversationId?

    override func toPresentable() -> DismissableVC {
        return self.peopleNavController
    }

    override func start() {
        super.start()
        
        self.peopleNavController.peopleVC.button.didSelect { [unowned self] in
            self.peopleNavController.prepareForInvitations()
            
            Task {
                await self.updateInvitation()
            }.add(to: self.taskPool)
        }
    }
}

