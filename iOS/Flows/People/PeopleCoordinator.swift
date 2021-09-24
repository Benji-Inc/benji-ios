//
//  NewConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class PeopleCoordinator: PresentableCoordinator<ChatChannelController?> {

    lazy var newConversationVC = PeopleViewController()

    override func toPresentable() -> DismissableVC {
        return self.newConversationVC
    }

    override func start() {
        super.start()

        self.newConversationVC.delegate = self
    }
}

extension PeopleCoordinator: NewConversationViewControllerDelegate {
    nonisolated func peopleView(_ controller: PeopleViewController, didCreate conversationController: ChatChannelController) {

        Task.onMainActor {
            self.finishFlow(with: conversationController)
        }
    }
}
