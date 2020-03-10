//
//  MainCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

class MainCoordinator: Coordinator<Void> {

    var launchOptions: [UIApplication.LaunchOptionsKey : Any]?

    override func start() {
        super.start()

        self.runLaunchFlow()
    }

    private func runLaunchFlow() {

        LaunchManager.shared.launchApp(with: self.launchOptions)

        let launchCoordinator = LaunchCoordinator(router: self.router, deepLink: self.deepLink)

        self.router.setRootModule(launchCoordinator, animated: true)
        self.addChildAndStart(launchCoordinator, finishedHandler: { (_) in })

        LaunchManager.shared.status.producer.on { [weak self] (result) in
            guard let `self` = self else { return }
            self.handle(result: result)
        }
        .start()
    }

    private func handle(result: LaunchStatus) {

        switch result {
        case .isLaunching:
            break
        case .needsOnboarding:
            runMain {
                self.runOnboardingFlow()
            }
        case .success(let object, let token):
            self.deepLink = object

            if ChannelManager.shared.isConnected {
                self.runHomeFlow()
            } else {
                self.initializeChat(with: token)
            }
        case .failed(_):
            break
        case .deeplink(let object):
            self.deepLink = object
            self.handle(deeplink: object)
        }
    }

    private func initializeChat(with token: String) {
        ChannelManager.initialize(token: token)
            .withResultToast()
            .observeValue(with: { (_) in
                runMain {
                    self.runHomeFlow()
                }
            })
    }

    private func runHomeFlow() {
        let homeCoordinator = HomeCoordinator(router: self.router, deepLink: self.deepLink)
        self.router.setRootModule(homeCoordinator, animated: true)
        self.addChildAndStart(homeCoordinator, finishedHandler: { _ in
            // If the home coordinator ever finishes, put handling logic here.
        })
    }

    private func runOnboardingFlow() {
        let coordinator = OnboardingCoordinator(router: self.router, deepLink: self.deepLink)
        self.router.setRootModule(coordinator, animated: true)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
                self.runLaunchFlow()
            }
        })
    }

    private func handle(deeplink: DeepLinkable) {
        guard let code = deeplink.code else { return }

        //Apply code to 
    }
}

