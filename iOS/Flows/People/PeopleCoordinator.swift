//
//  NewConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Contacts

class PeopleCoordinator: PresentableCoordinator<ChatChannelController?> {

    lazy var peopleVC = PeopleViewController()

    override func toPresentable() -> DismissableVC {
        return self.peopleVC
    }

    override func start() {
        super.start()

        self.peopleVC.delegate = self
    }
}

extension PeopleCoordinator: PeopleViewControllerDelegate {

    nonisolated func peopleView(_ controller: PeopleViewController, didSelect item: PeopleCollectionViewDataSource.ItemType) {
        // Do stuff

        switch item {
        case .connection(_):
            break
        case .contact(let contact):
            Task {
                await self.didSelect(contact: contact)
            }
        }
    }

    private func didSelect(contact: CNContact) {
        // Trigger invite flow
    }
}
