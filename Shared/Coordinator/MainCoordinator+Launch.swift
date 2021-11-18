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

    func handle(result: LaunchStatus) {
        switch result {
        case .success(let object):
            self.deepLink = object

            if User.current().isNil {
                self.runOnboardingFlow()
            } else if let user = User.current(), !user.isOnboarded {
                self.runOnboardingFlow()
            } else {
                self.runConversationListFlow()
            }
        case .failed(_):
            break
        }
    }

    func runConversationListFlow() {
        if ChatClient.isConnected {
            if let coordinator = self.childCoordinator as? ConversationListCoordinator {
                if let deepLink = self.deepLink {
                    coordinator.handle(deeplink: deepLink)
                }
                Task {
                    await self.checkForPermissions()
                }
            } else {
                Task {
                    self.removeChild()
                    let query = ChannelListQuery(filter: .containMembers(userIds: [User.current()!.objectId!]),
                                                 sort: [.init(key: .lastMessageAt, isAscending: false)],
                                            pageSize: 20)
                    let channelListController = try? await ChatClient.shared.queryChannels(query: query)
                    guard let conversation = channelListController?.channels.first else { return }

                    let membersController = ChatClient.shared.memberListController(query: .init(cid: conversation.cid))
                    try? await membersController.synchronize()

                    let members = Array(membersController.members)

                    let coordinator = ConversationListCoordinator(router: self.router,
                                                                  deepLink: self.deepLink,
                                                                  conversationMembers: members,
                                                                  startingConversationID: conversation.cid)
                    self.addChildAndStart(coordinator, finishedHandler: { (_) in

                    })
                    self.router.push(coordinator, cancelHandler: {
                    }, animated: true)

                    Task {
                        await self.checkForPermissions()
                    }
                }
            }
        } else {
            Task {
                try await ChatClient.initialize(for: User.current()!)
                self.runConversationListFlow()
            }
        }
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


