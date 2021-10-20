//
//  MainCoordinator+Launch.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension MainCoordinator {
#if !APPCLIP && !NOTIFICATION
    func handle(result: LaunchStatus) {
        switch result {
        case .success(let object):
            self.deepLink = object

            if User.current().isNil {
                self.runOnboardingFlow()
            } else if let user = User.current(), !user.isOnboarded {
                self.runOnboardingFlow()
            } else if ChatClient.isConnected {
                if let deepLink = object {
                    self.handle(deeplink: deepLink)
                } else {
                    self.runArchiveFlow()
                    //self.runHomeFlow()
                }
            }
        case .failed(_):
            break
        }
    }

    #warning("Replace with HomeCoordinator after beta features are complete.")
    func runArchiveFlow() {
        if ChatClient.isConnected {
            if let coordinator = self.childCoordinator as? ArchiveCoordinator {
                if let deepLink = self.deepLink {
                    coordinator.handle(deeplink: deepLink)
                }
            } else {
                self.removeChild()
                let coordinator = ArchiveCoordinator(router: self.router, deepLink: self.deepLink)
                self.router.setRootModule(coordinator, animated: true)
                self.addChildAndStart(coordinator, finishedHandler: { _ in
                    // If the home coordinator ever finishes, put handling logic here.
                })
            }
        } else {
            Task {
                try await ChatClient.initialize(for: User.current()!)
                self.runArchiveFlow()
            }
        }
    }

//    func runHomeFlow() {
//        if let homeCoordinator = self.childCoordinator as? HomeCoordinator {
//            if let deepLink = self.deepLink {
//                homeCoordinator.handle(deeplink: deepLink)
//            }
//        } else {
//            self.removeChild()
//            let homeCoordinator = HomeCoordinator(router: self.router, deepLink: self.deepLink)
//            self.router.setRootModule(homeCoordinator, animated: true)
//            self.addChildAndStart(homeCoordinator, finishedHandler: { _ in
//                // If the home coordinator ever finishes, put handling logic here.
//            })
//        }
//    }

    func logOutChat() {
        ChatClient.shared.disconnect()
    }
#endif
}
