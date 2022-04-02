//
//  MainCoordinator+Launch.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

#if IOS
extension MainCoordinator {

    @MainActor
    func runConversationListFlow(with deepLink: DeepLinkable?) async {
        // Ensure that the chat client is initialized for the logged in user.
        if !ChatClient.isConnected || ChatClient.shared.currentUserId != User.current()?.objectId {
            try? await ChatClient.initialize(for: User.current()!)
        }
        
        if let coordinator = self.childCoordinator as? RoomCoordinator,
           let link = deepLink {
            coordinator.handle(deeplink: link)
        } else {
            let coordinator = RoomCoordinator(router: self.router, deepLink: self.deepLink)
            self.addChildAndStart(coordinator, finishedHandler: { (_) in})
            self.router.setRootModule(coordinator)
        }
    }

    func logOutChat() {
        ChatClient.shared?.disconnect()
    }
}
#endif
