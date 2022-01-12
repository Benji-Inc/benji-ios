//
//  LaunchCoordinator.swift
//  Jibber
//
//  Created by Martin Young on 1/12/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

class LaunchCoordinator: PresentableCoordinator<LaunchStatus> {

    lazy var splashVC = SplashViewController()

    override func toPresentable() -> DismissableVC {
        return self.splashVC
    }

    override func start() {
        super.start()

        Task {
            let launchStatus = await LaunchManager.shared.launchApp()

            self.finishFlow(with: launchStatus)
        }
    }
}
