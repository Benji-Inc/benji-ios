//
//  NewConversationCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 10/5/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class NewConversationCoordinator: PresentableCoordinator<Bool> {

    lazy var newConversationVC = NewConversationViewController()

    override func toPresentable() -> DismissableVC {
        return self.newConversationVC
    }

    override func start() {
        super.start()

        self.newConversationVC.didCreateConversation = { [unowned self] in 
            self.finishFlow(with: true)
        }
    }
}
