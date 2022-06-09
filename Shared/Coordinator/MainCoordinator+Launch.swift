//
//  MainCoordinator+Launch.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension MainCoordinator {

    @MainActor
    func runHomeFlow(with deepLink: DeepLinkable?) async {
        // Ensure that the chat client is initialized for the logged in user.
        if !JibberChatClient.shared.isConnected || JibberChatClient.shared.isConnectedToCurrentUser {
            try? await JibberChatClient.shared.initialize(for: User.current()!)
        }
        
        if let coordinator = self.furthestChild as? LaunchActivityHandler,
           let launchActivity = self.launchActivity {
            coordinator.handle(launchActivity: launchActivity)
        } else if let coordinator = self.furthestChild as? DeepLinkHandler,
           let link = deepLink {
            coordinator.handle(deepLink: link)
        } else {
            let coordinator = RoomCoordinator(router: self.router, deepLink: self.deepLink)
            self.addChildAndStart(coordinator, finishedHandler: { (_) in})
            self.router.setRootModule(coordinator)
            if let activity = self.launchActivity {
                coordinator.handle(launchActivity: activity)
            } else if let deepLink = deepLink {
                coordinator.handle(deepLink: deepLink)
            }
        }
    }

    func logOutChat() {
        JibberChatClient.shared.disconnect()
    }
}
