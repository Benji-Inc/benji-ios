//
//  MainCoordinator+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/16/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery

extension MainCoordinator: UserNotificationManagerDelegate {
    
    nonisolated func userNotificationManager(willHandle deeplink: DeepLinkable) {
        Task.onMainActor {
            self.deepLink = deeplink
            self.handle(deeplink: deeplink)
        }
    }
}

extension MainCoordinator: LaunchManagerDelegate {

    nonisolated func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity) {
        Task.onMainActor {
            self.furthestChild.handle(launchActivity: activity)
        }
    }

    func subscribeToUserUpdates() {
        if let query = self.userQuery, let objectId = User.current()?.objectId {

            query.whereKey("objectId", equalTo: objectId)

            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { query, event in
                switch event {
                case .deleted(_):
                    self.showLogOutAlert()
                default:
                    break
                }
            }
        }
    }

#if APPCLIP
    func handleAppClip(result: LaunchStatus) {
        switch result {
        case .success(let object, _):
            self.deepLink = object
            self.runOnboardingFlow()
        case .failed(_):
            break
        }
    }
#endif
}
