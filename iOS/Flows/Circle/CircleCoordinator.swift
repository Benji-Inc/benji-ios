//
//  CircleCoordinator.swift
//  CircleCoordinator
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CircleCoordinator: PresentableCoordinator<Void> {

    private lazy var circleVC: CircleViewController = {
        let vc = CircleViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.circleVC
    }

    override func start() {
        super.start()

    }
}

extension CircleCoordinator: CircleViewControllerDelegate {

    nonisolated func circleView(_ controller: CircleViewController, didSelect item: CircleCollectionViewDataSource.ItemType) {

    }
}
