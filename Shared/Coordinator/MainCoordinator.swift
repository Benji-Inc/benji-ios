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
        #if !APPCLIP && !NOTIFICATION
        UserNotificationManager.shared.delegate = self
        #endif

        Task {
            await self.runLaunchFlow()
        }
    }

    private func runLaunchFlow() async {
        self.router.setRootModule(self.splashVC, animated: false)

        let launchStatus = await LaunchManager.shared.launchApp(with: self.launchOptions)

#if !APPCLIP && !NOTIFICATION
        // Code you don't want to use in your App Clip.
        self.handle(result: launchStatus)
#elseif !NOTIFICATION
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
            self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (conversationId) in

                /// Set the conversationId on the deeplink so it gets passed up and displayed
                if let id = conversationId {
                    self.deepLink?.conversationId = id
                    self.deepLink?.deepLinkTarget = .conversation
                }
#if APPCLIP
                
                //Add the conversationId to shared storage so it can open once they download the full app.
#elseif !NOTIFICATION
                    self.runArchiveFlow()
                    //self.runHomeFlow()
#endif
                    self.subscribeToUserUpdates()
            })
        }
    }

    func handle(deeplink: DeepLinkable) {
        guard let string = deeplink.customMetadata["target"] as? String,
              let target = DeepLinkTarget(rawValue: string)  else { return }
        switch target {
        case .home, .conversation, .archive:
            if let user = User.current(), user.isAuthenticated {
#if !APPCLIP && !NOTIFICATION
                // Code you don't want to use in your App Clip.
                self.runArchiveFlow()
                //self.runHomeFlow()
#else
                // Code your App Clip may access.
#endif
            }
        case .login:
            break
        case .reservation:
            if let user = User.current(), user.isAuthenticated {
#if !APPCLIP && !NOTIFICATION
                // Code you don't want to use in your App Clip.
                self.runArchiveFlow()
                //self.runHomeFlow()
#else
                // Code your App Clip may access.
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
#if !APPCLIP && !NOTIFICATION
        self.logOutChat()
#endif
        User.logOut()
        self.deepLink = nil
        self.removeChild()
        self.runOnboardingFlow()
    }
}

#if !APPCLIP && !NOTIFICATION
extension MainCoordinator: UserNotificationManagerDelegate {

    nonisolated func userNotificationManager(willHandle deeplink: DeepLinkable) {
        Task.onMainActor {
            self.deepLink = deeplink
            self.handle(deeplink: deeplink)
        }
    }
}
#endif

