//
//  CirclesCoordinator.swift
//  CirclesCoordinator
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleGroupCoordinator: PresentableCoordinator<Void> {

    private lazy var circlesVC: CircleGroupViewController = {
        let vc = CircleGroupViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.circlesVC
    }

    override func start() {
        super.start()

        self.circlesVC.didSelectReservations = { [unowned self] in
            self.startReservationsFlow()
        }
    }

    func startReservationsFlow() {
        self.removeChild()
        let coordinator = ReservationsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in }
        self.router.present(coordinator, source: self.circlesVC)
    }
}

extension CircleGroupCoordinator: CircleGroupViewControllerDelegate {

    nonisolated func circleGroupView(_ controller: CircleGroupViewController, didSelect item: CircleGroupCollectionViewDataSource.ItemType) {

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
