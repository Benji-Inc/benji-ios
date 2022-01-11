//
//  MainCoordinator.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit
import Parse

class MainCoordinator: Coordinator<Void> {

    lazy var splashVC = SplashViewController()

    override func start() {
        super.start()

        SessionManager.shared.didReceiveInvalidSessionError = { [unowned self] _ in
            Task.onMainActor {
                self.showLogOutAlert()
            }
        }

        LaunchManager.shared.delegate = self
        
        #if IOS
        UserNotificationManager.shared.delegate = self
        ToastScheduler.shared.delegate = self
        #endif

        Task {
            await self.runLaunchFlow()
        }.add(to: self.taskPool)
    }

    private func runLaunchFlow() async {
        self.router.setRootModule(self.splashVC, animated: false)

        let launchStatus = await LaunchManager.shared.launchApp()

        #if IOS
        self.handle(result: launchStatus)
        #elseif APPCLIP
        // Code your App Clip may access.
        self.handleAppClip(result: launchStatus)
        #endif

        self.subscribeToUserUpdates()
    }

    func runOnboardingFlow() {
        if let onboardingCoordinator = self.childCoordinator as? OnboardingCoordinator {
            onboardingCoordinator.handle(deeplink: self.deepLink)
        } else {
            let coordinator = OnboardingCoordinator(router: self.router,
                                                    deepLink: self.deepLink)
            self.router.setRootModule(coordinator, animated: true)
            self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
                self.subscribeToUserUpdates()

                #if IOS
                Task {
                    await self.runConversationListFlow()
                }.add(to: self.taskPool)
                #endif
            })
        }
    }

    func runWaitlistFlow() {
        let waitlistCoordinator = WaitlistCoordinator(router: self.router, deepLink: nil)
        self.router.setRootModule(waitlistCoordinator)
        self.addChildAndStart(waitlistCoordinator) { _ in

        }
    }

    func handle(deeplink: DeepLinkable) {
        guard let target = deeplink.deepLinkTarget else { return }

        self.deepLink = deeplink

        switch target {
        case .home, .conversation, .archive:
            guard let user = User.current(), user.isAuthenticated else { return }
            #if IOS

            Task {
                await self.runConversationListFlow()
            }.add(to: self.taskPool)
            #endif
        case .login:
            break
        case .reservation:
            if let user = User.current(), user.isAuthenticated {
            #if IOS
                Task {
                    await self.runConversationListFlow()
                }.add(to: self.taskPool)
            #endif
            } else {
                self.runOnboardingFlow()
            }
        }
    }

    func showLogOutAlert() {
        let alert = UIAlertController(title: "🙀",
                                      message: "Someone tripped over a 🐈 and ☠️ the mainframe.",
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.logOut()
        }
        
        alert.addAction(ok)

        if self.router.topmostViewController is UIAlertController {
        } else {
            self.router.topmostViewController.present(alert, animated: true, completion: nil)
        }
    }

    private func logOut() {
        #if IOS
        self.logOutChat()
        #endif
        User.logOut()
        self.deepLink = nil
        self.removeChild()
        self.runOnboardingFlow()
    }
}

#if IOS
extension MainCoordinator: UserNotificationManagerDelegate {

    nonisolated func userNotificationManager(willHandle deeplink: DeepLinkable) {
        Task.onMainActor {
            self.deepLink = deeplink
            self.handle(deeplink: deeplink)
        }
    }
}
#endif

