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

    override func start() {
        super.start()

        SessionManager.shared.didReceiveInvalidSessionError = { [unowned self] _ in
            Task.onMainActor {
                self.showLogOutAlert()
            }
        }

        LaunchManager.shared.delegate = self
        self.subscribeToUserUpdates()
        
#if IOS
        UserNotificationManager.shared.delegate = self
        ToastScheduler.shared.delegate = self
#endif

        self.runLaunchFlow()
    }

    /// A task to start the launch flow and
    private var launchAndDeepLinkTask: Task<Void, Never>?
    private func runLaunchFlow() {
        self.launchAndDeepLinkTask?.cancel()

        self.launchAndDeepLinkTask = Task {
            let launchStatus: LaunchStatus = await withCheckedContinuation { continuation in
                let launchCoordinator = LaunchCoordinator(router: self.router, deepLink: self.deepLink)
                self.router.setRootModule(launchCoordinator)
                self.addChildAndStart(launchCoordinator) { launchStatus in
                    continuation.resume(returning: launchStatus)
                }
            }

            // Don't handle the launch status if the task was cancelled.
            guard !Task.isCancelled else { return }

#if IOS
            self.handle(result: launchStatus)
#elseif APPCLIP
            // Code your App Clip may access.
            self.handleAppClip(result: launchStatus)
#endif
        }
    }

    private func handle(result: LaunchStatus) {
        switch result {
        case .success(let deepLink):
            if let deepLink = deepLink {
                self.handle(deeplink: deepLink)
            } else {
                self.handle(deeplink: DeepLinkObject(target: .conversation))
            }
        case .failed(_):
            break
        }
    }

    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        // NOTE: Regardless of the deep link, the user needs to be created and activated to get
        // to the whole app.

        // If no user object has been created, allow the user to do so now.
        guard let user = User.current(), user.isAuthenticated else {
            self.runOnboardingFlow(with: deeplink)
            return
        }

        // If ther user didn't finish onboarding, redirect them to onboarding
        if !user.isOnboarded {
            self.runOnboardingFlow(with: deeplink)
            return
        }

        // As a final catch-all, make sure the user is fully activated.
        guard user.status == .active || user.status == .waitlist else {
            self.runOnboardingFlow(with: deeplink)
            return
        }

        // Clean up the deep link when we're done
        defer {
            self.deepLink = nil
        }

        guard let target = deeplink.deepLinkTarget else { return }

        // Now attempt to handle the deeplink.
        switch target {
        case .home, .conversation:
#if IOS
            Task {
                await self.runConversationListFlow(with: deeplink)
            }
#endif
        case .login:
            self.runOnboardingFlow(with: deeplink)
        case .reservation:
#if IOS
            Task {
                await self.runConversationListFlow(with: deeplink)
            }
#endif
            self.runOnboardingFlow(with: deeplink)
        }
    }

    func runOnboardingFlow(with deepLink: DeepLinkable?) {
        let coordinator = OnboardingCoordinator(router: self.router,
                                                deepLink: deepLink)
        self.router.setRootModule(coordinator, animated: true)
        self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
            // Attempt to take the user to the conversation screen after onboarding is complete.
            self.handle(deeplink: DeepLinkObject(target: .conversation))
        })
    }

    func showLogOutAlert() {
        let alert = UIAlertController(title: "🙀",
                                      message: "Someone tripped over a 🐈 and ☠️ the mainframe.",
                                      preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default) { [unowned self] (_) in
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
        self.runOnboardingFlow(with: nil)
    }
}

#if IOS

// MARK: - UserNotificationManagerDelegate

extension MainCoordinator: UserNotificationManagerDelegate {

    nonisolated func userNotificationManager(willHandle deeplink: DeepLinkable) {
        Task.onMainActorAsync {
            // Cancelling other deeplink calls.
            self.launchAndDeepLinkTask?.cancel()

            // Wait until the launch is finished.
            await self.launchAndDeepLinkTask?.value

            self.handle(deeplink: deeplink)
        }
    }
}
#endif
