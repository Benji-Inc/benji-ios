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
            switch activity {
            case .deepLink(let deepLinkable):
                self.handle(deeplink: deepLinkable)
            default:
                if let furthestChild = self.furthestChild as? LaunchActivityHandler {
                    furthestChild.handle(launchActivity: activity)
                } else {
                    // We may not have completed launching yet, so store it
                    self.launchActivity = activity
                }
            }
        }
    }

    func subscribeToUserUpdates() {
        PeopleStore.shared.$personDeleted
            .filter({ person in
                guard let personId = person?.personId else { return false }
                return personId == User.current()?.personId
            })
            .mainSink { [unowned self] user in
                self.logOut()
            }.store(in: &self.cancellables)
    }

#if APPCLIP
    func handleAppClip(deepLink object: DeepLinkable) {
        self.deepLink = object
        self.runOnboardingFlow(with: object)
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
