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
        if !ChatClient.isConnected || ChatClient.shared.currentUserId != User.current()?.userObjectId {
            try? await ChatClient.initialize(for: User.current()!)
        }

        let startingCID = deepLink?.conversationId
        let startingMessageId = deepLink?.messageId

        let coordinator = ConversationListCoordinator(router: self.router,
                                                      deepLink: deepLink,
                                                      conversationMembers: [],
                                                      startingConversationId: startingCID,
                                                      startingMessageId: startingMessageId)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in })

        self.router.setRootModule(coordinator)
    }

    func logOutChat() {
        ChatClient.shared.disconnect()
    }
}
#endif
