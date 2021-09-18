//
//  CirclesCoordinator.swift
//  CirclesCoordinator
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleGroupCoordinator: PresentableCoordinator<Void> {

    private lazy var circlesVC: CirclesViewController = {
        let vc = CirclesViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.circlesVC
    }

    override func start() {
        super.start()

    }
}

extension CircleGroupCoordinator: CirclesViewControllerDelegate {

    nonisolated func circlesView(_ controller: CirclesViewController, didSelect item: CirclesCollectionViewDataSource.ItemType) {

        switch item {
        case .circles(let group):
            Task.onMainActor {
                self.startCircleFlow(with: group)
            }
        }
    }

    func startCircleFlow(with group: CircleGroup) {
        self.removeChild()
        let coordinator = CircleCoordinator(with: group,
                                            router: self.router,
                                            deepLink: self.deepLink)

        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true) {

            }
        }
        self.router.present(coordinator, source: self.circlesVC)
    }
}
