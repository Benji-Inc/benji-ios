//
//  MainCoordinator+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/16/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension MainCoordinator: LaunchManagerDelegate {

    nonisolated func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity) {
        Task.onMainActor {
            if let furthestChild = self.furthestChild as? LaunchActivityHandler {
                furthestChild.handle(launchActivity: activity)
            }
        }
    }

    func subscribeToUserUpdates() {
        UserStore.shared.$userDeleted
            .filter({ user in
                user?.isCurrentUser ?? false
            })
            .mainSink { user in
                self.showLogOutAlert()
            }.store(in: &self.cancellables)
    }

    #if APPCLIP
    func handleAppClip(result: LaunchStatus) {
        switch result {
        case .success(let object):
            self.deepLink = object
            self.runOnboardingFlow()
        case .failed(_):
            break
        }
    }
    #endif
}

extension MainCoordinator: ToastSchedulerDelegate {

    nonisolated func didInteractWith(type: ToastType, deeplink: DeepLinkable?) {
        Task.onMainActor {
            guard let link = deeplink else { return }
            self.handle(deeplink: link)
        }
    }
}
