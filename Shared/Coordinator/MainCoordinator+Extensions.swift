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
    func userNotificationManager(willHandle deeplink: DeepLinkable) {
        self.deepLink = deeplink
        self.handle(deeplink: deeplink)
    }
}

extension MainCoordinator: LaunchManagerDelegate {

    func launchManager(_ manager: LaunchManager, didReceive activity: LaunchActivity) {
        self.furthestChild.handle(launchActivity: activity)
    }

    func launchManager(_ manager: LaunchManager, didFinishWith status: LaunchStatus) {
        #if !APPCLIP && !NOTIFICATION
        // Code you don't want to use in your App Clip.
        self.handle(result: status)
        #elseif !NOTIFICATION
        // Code your App Clip may access.
        self.handleAppClip(result: status)
        #endif

        self.subscribeToUserUpdates()
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
            runMain {
                self.runOnboardingFlow()
            }
        case .failed(_):
            break
        }
    }
    #endif
}
