//
//  CircleCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/26/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {

    lazy var circleVC = CircleViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.circleVC
    }

    override func start() {
        super.start()

       
    }
    
    func presentPeoplePicker() {

        self.removeChild()
        let coordinator = PeopleCoordinator(conversationID: nil,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        // Because of how the People are presented, we need to properly reset the KeyboardManager.
        coordinator.toPresentable().dismissHandlers.append { [unowned self] in
        }

        self.addChildAndStart(coordinator) { [unowned self] connections in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                //self.conversationListVC.becomeFirstResponder()
                //self.add(connections: connections, to: conversation)
            }
        }

        self.router.present(coordinator, source: self.circleVC)
    }
}
