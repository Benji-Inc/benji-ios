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

        self.circleVC.$selectedItems.mainSink { [unowned self] items in
            guard !items.isEmpty else { return }
            self.presentPeoplePicker()
        }.store(in: &self.cancellables)
    }
    
    func presentPeoplePicker() {

        self.removeChild()
        let coordinator = PeopleCoordinator(conversationID: nil,
                                            router: self.router,
                                            deepLink: self.deepLink)
        
        self.addChildAndStart(coordinator) { [unowned self] connections in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) { [unowned self] in
                self.updateCircle(with: connections)
            }
        }

        self.router.present(coordinator, source: self.circleVC)
    }
    
    func updateCircle(with connections: [Connection]) {
        
    }
}
