//
//  CirclesCoordinator.swift
//  CirclesCoordinator
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class CirclesCoordinator: PresentableCoordinator<Void> {

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

extension CirclesCoordinator: CirclesViewControllerDelegate {

    nonisolated func circlesView(_ controller: CirclesViewController, didSelect item: CirclesCollectionViewDataSource.ItemType) {

    }
}
