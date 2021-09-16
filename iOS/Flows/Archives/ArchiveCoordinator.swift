//
//  ArchiveCoordinator.swift
//  ArchiveCoordinator
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchiveCoordinator: PresentableCoordinator<Void> {

    private lazy var archiveVC: ArchiveViewController = {
        let vc = ArchiveViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.archiveVC
    }

    override func start() {
        super.start()
        
    }
}

extension ArchiveCoordinator: ArchiveViewControllerDelegate {

    nonisolated func archiveView(_ controller: ArchiveViewController, didSelect item: ArchiveCollectionViewDataSource.ItemType) {

    }
}
