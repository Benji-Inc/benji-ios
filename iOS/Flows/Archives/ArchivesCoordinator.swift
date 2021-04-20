//
//  ArchivesCoordinator.swift
//  Ours
//
//  Created by Benji Dodgson on 4/20/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ArchivesCoordinator: PresentableCoordinator<Void> {

    lazy var archivesVC = ArchivesViewController()

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.archivesVC
    }

    override func start() {
        super.start()


        self.archivesVC.didSelectPost = { [unowned self] post in
            self.present(post: post)
        }
    }

    private func present(post: Post) {
        let vc = PostMediaViewController(with: post)
        self.router.present(vc, source: self.archivesVC)
    }
}
