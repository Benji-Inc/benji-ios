//
//  SplashCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 8/20/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

// Presents the splash view controller and tells the launch manager to start retrieving
// user data. Once the data is retrieved, it checks if the app needs to be updated, and presents the
// update flow if needed.

class LaunchCoordinator: PresentableCoordinator<LaunchStatus> {

    private lazy var splashVC = SplashViewController()
    private let launchOptions: [UIApplication.LaunchOptionsKey : Any]?

    override func toPresentable() -> DismissableVC {
        return self.splashVC
    }

    init(with launchOptions: [UIApplication.LaunchOptionsKey : Any]?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.launchOptions = launchOptions
        super.init(router: router, deepLink: deepLink)
    }

    override func start() {
        super.start()

        LaunchManager.shared.delegate = self
        LaunchManager.shared.launchApp(with: self.launchOptions)
    }
}

extension LaunchCoordinator: LaunchManagerDelegate {

    func launchManager(_ manager: LaunchManager, didFinishWith status: LaunchStatus) {
        self.finishFlow(with: status)
    }
}

