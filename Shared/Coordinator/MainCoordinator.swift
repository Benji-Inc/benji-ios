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

    var launchOptions: [UIApplication.LaunchOptionsKey : Any]?

    lazy var splashVC = SplashViewController()

    override func start() {
        super.start()

        SessionManager.shared.didReceiveInvalidSessionError = { [unowned self] _ in
            self.showLogOutAlert()
        }

        LaunchManager.shared.delegate = self
        
        #if IOS
        UserNotificationManager.shared.delegate = self
        ToastScheduler.shared.delegate = self
        #endif

        Task {
            await self.runLaunchFlow()
        }
    }

    private func runLaunchFlow() async {
        self.router.setRootModule(self.splashVC, animated: false)

        let launchStatus = await LaunchManager.shared.launchApp(with: self.launchOptions)

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
                self.runConversationListFlow()
                #endif
            })
        }
    }


    func handle(deeplink: DeepLinkable) {
        guard let string = deeplink.customMetadata["target"] as? String,
              let target = DeepLinkTarget(rawValue: string)  else { return }
        switch target {
        case .home, .conversation, .archive:
            guard let user = User.current(), user.isAuthenticated else { return }
            #if IOS
            self.runConversationListFlow()
            #endif
        case .login:
            break
        case .reservation:
            if let user = User.current(), user.isAuthenticated {
            #if IOS
                self.runConversationListFlow()
            #endif
            } else {
                self.runOnboardingFlow()
            }
        }
    }

    @MainActor
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

