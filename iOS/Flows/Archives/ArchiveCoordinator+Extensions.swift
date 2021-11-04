//
//  ArchiveCoordinator+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents

extension ArchiveCoordinator: UserNotificationManagerDelegate {

    nonisolated func userNotificationManager(willHandle deeplink: DeepLinkable) {
        Task.onMainActor {
            self.deepLink = deeplink
            self.handle(deeplink: deeplink)
        }
    }
}

#warning("Remove after beta features are complete.")
extension ArchiveCoordinator: ToastSchedulerDelegate {
    
    nonisolated func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        Task.onMainActor {
            guard let link = deeplink else { return }
            self.handle(deeplink: link)
        }
    }
}

extension ArchiveCoordinator {

    @MainActor
    func checkForPermissions() async {
        if INFocusStatusCenter.default.authorizationStatus != .authorized {
            self.presentPermissions()
        } else if await UserNotificationManager.shared.getNotificationSettings().authorizationStatus != .authorized {
            self.presentPermissions()
        }
    }

    @MainActor
    private func presentPermissions() {
        let coordinator = PermissionsCoordinator(router: self.router, deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { [unowned self] result in
            self.router.dismiss(source: coordinator.toPresentable(), animated: true)
        }
        self.router.present(coordinator, source: self.archiveVC)
    }
}
