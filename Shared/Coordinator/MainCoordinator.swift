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
import StreamChat

class MainCoordinator: Coordinator<Void> {

    var launchOptions: [UIApplication.LaunchOptionsKey : Any]?

    var isInitializingChat: Bool = false

    lazy var splashVC = SplashViewController()
    lazy var userQuery = User.query() // Will crash if initialized before parse registers the subclass

    override func start() {
        super.start()

        SessionManager.shared.didReceiveInvalidSessionError = { [unowned self] _ in
            self.showLogOutAlert()
        }

        UserNotificationManager.shared.delegate = self
        LaunchManager.shared.delegate = self

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

#if !APPCLIP && !NOTIFICATION
    func handle(result: LaunchStatus) {
        switch result {
        case .success(let object, let token):




            self.deepLink = object

            if User.current().isNil {
                self.runOnboardingFlow()
            } else if let user = User.current(), !user.isOnboarded {
                self.runOnboardingFlow()
            } else if ChatClientManager.shared.isConnected {
                self.runHomeFlow()
            } else if !token.isEmpty {
                Task {
                    do {
                        try await new_ChatClientManager.shared.initialize()
                        self.runHomeFlow()
                    } catch {
                        logDebug(error)
                    }
                }

                #warning("Restore this if necessary")
//                Task {
//                    do {
//                        try await self.initializeChat(with: token)
//                    } catch {
//                        print(error)
//                    }
//                }
            } else if let deeplink = object {
                self.handle(deeplink: deeplink)
            }
        case .failed(_):
            break
        }
    }

    private func runHomeFlow() {
        if let homeCoordinator = self.childCoordinator as? HomeCoordinator {
            if let deepLink = self.deepLink {
                homeCoordinator.handle(deeplink: deepLink)
            }
        } else if ChatClientManager.shared.isSynced {
            self.removeChild()
            let homeCoordinator = HomeCoordinator(router: self.router, deepLink: self.deepLink)
            self.router.setRootModule(homeCoordinator, animated: true)
            self.addChildAndStart(homeCoordinator, finishedHandler: { _ in
                // If the home coordinator ever finishes, put handling logic here.
            })
        } else {
            Task {
                do {
                    try await self.getChatToken()
                } catch {
                    print(error)
                }
            }
        }
    }

    func getChatToken() async throws {
        let token = try await GetChatToken().makeRequest(andUpdate: [], viewsToIgnore: [])
        try await self.initializeChat(with: token)
    }

    private func initializeChat(with token: String) async throws {
        // Fixes double loading.
        guard !self.isInitializingChat else { return }

        self.isInitializingChat = true

        try await ChatClientManager.shared.initialize(token: token)

        self.isInitializingChat = false

        guard let user = User.current(), user.isOnboarded else { return }

        if let user = User.current(), user.isOnboarded {
            if let deeplink = self.deepLink {
                self.handle(deeplink: deeplink)
            } else {
                self.runHomeFlow()
            }
        } else {
            self.runOnboardingFlow()
        }
    }
#endif

    func runOnboardingFlow() {
        if let onboardingCoordinator = self.childCoordinator as? OnboardingCoordinator {
            onboardingCoordinator.handle(deeplink: deepLink)
        } else {
            let coordinator = OnboardingCoordinator(reservationId: self.deepLink?.reservationId,
                                                    reservationCreatorId: self.deepLink?.reservationCreatorId,
                                                    router: self.router,
                                                    deepLink: self.deepLink)
            self.router.setRootModule(coordinator, animated: true)
            self.addChildAndStart(coordinator, finishedHandler: { (_) in
                self.router.dismiss(source: coordinator.toPresentable(), animated: true) {
#if APPCLIP
#elseif !NOTIFICATION
                    self.runHomeFlow()
#endif
                    self.subscribeToUserUpdates()
                }
            })
        }
    }

    func handle(deeplink: DeepLinkable) {
        guard let string = deeplink.customMetadata["target"] as? String,
              let target = DeepLinkTarget(rawValue: string)  else { return }
        switch target {
        case .home, .conversation, .conversations:
            if let user = User.current(), user.isAuthenticated {
#if !APPCLIP && !NOTIFICATION
                // Code you don't want to use in your App Clip.
                self.runHomeFlow()
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
                self.runHomeFlow()
#else
                // Code your App Clip may access.
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
#if !APPCLIP && !NOTIFICATION
        ChatClientManager.shared.client?.shutdown()
#endif
        User.logOut()
        self.deepLink = nil
        self.removeChild()
        self.runOnboardingFlow()
    }
}
