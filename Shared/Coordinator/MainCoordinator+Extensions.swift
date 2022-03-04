//
//  MainCoordinator+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/16/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery

extension MainCoordinator: LaunchManagerDelegate {

    nonisolated func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity) {
        Task.onMainActor {
            guard let furthestChild = self.furthestChild as? LaunchActivityHandler else { return }
            furthestChild.handle(launchActivity: activity)
        }
    }

    func subscribeToUserUpdates() {
        PeopleStore.shared.$personDeleted
            .filter({ person in
                guard let personId = person?.personId else { return false }
                return personId == User.current()?.personId
            })
            .mainSink { [unowned self] user in
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
