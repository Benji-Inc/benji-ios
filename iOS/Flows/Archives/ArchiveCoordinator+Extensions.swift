//
//  ArchiveCoordinator+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

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
