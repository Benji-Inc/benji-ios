//
//  NewConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class NewConversationCoordinator: PresentableCoordinator<ChatChannelController?> {

    lazy var newConversationVC = NewConversationViewController()

    override func toPresentable() -> DismissableVC {
        return self.newConversationVC
    }

    override func start() {
        super.start()

        self.newConversationVC.delegate = self
    }
}

extension NewConversationCoordinator: NewConversationViewControllerDelegate {
    nonisolated func newConversationView(_ controller: NewConversationViewController, didCreate conversationController: ChatChannelController) {

        Task.onMainActor {
            self.finishFlow(with: conversationController)
        }
    }
}
