//
//  MainCoordinator+Launch.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Intents

#if IOS
extension MainCoordinator {

    @MainActor
    func runConversationListFlow() async {
        // Ensure that the chat client is initialized for the logged in user.
        if !ChatClient.isConnected || ChatClient.shared.currentUserId != User.current()?.userObjectId {
            try? await ChatClient.initialize(for: User.current()!)
        }

        let startingCID = self.deepLink?.conversationId
        let startingMessageId = self.deepLink?.messageId

        let coordinator = ConversationListCoordinator(router: self.router,
                                                      deepLink: self.deepLink,
                                                      conversationMembers: [],
                                                      startingConversationId: startingCID,
                                                      startingMessageId: startingMessageId)
        self.addChildAndStart(coordinator, finishedHandler: { (_) in })

        self.router.setRootModule(coordinator)

        await self.checkForPermissions()
    }

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
        self.router.present(coordinator, source: self.router.topmostViewController)
    }

    func logOutChat() {
        ChatClient.shared.disconnect()
    }
}
#endif
