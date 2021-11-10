//
//  ArchiveCoordinator.swift
//  ArchiveCoordinator
//
//  Created by Benji Dodgson on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Intents

class ArchiveCoordinator: PresentableCoordinator<Void> {

    lazy var archiveVC: ArchiveViewController = {
        let vc = ArchiveViewController()
        vc.delegate = self
        return vc
    }()

    override func toPresentable() -> DismissableVC {
        return self.archiveVC
    }

    override func start() {
        super.start()

        Task {
            await self.checkForPermissions()
        }.add(to: self.archiveVC.taskPool)

        if let deeplink = self.deepLink {
            self.handle(deeplink: deeplink)
        }

        UserNotificationManager.shared.delegate = self
        
        ToastScheduler.shared.delegate = self
        _ = ConversationsManager.shared

        self.archiveVC.addButton.didSelect { [unowned self] in
            Task {
                await self.createConversation()
            }.add(to: self.archiveVC.taskPool)
        }
    }
    
    func handle(deeplink: DeepLinkable) {
        self.deepLink = deeplink

        guard let target = deeplink.deepLinkTarget else { return }

        switch target {
        case .conversation:
            if let identifier = deeplink.customMetadata["conversationId"] as? String {
                guard let conversationId = try? ChannelId.init(cid: identifier) else { return }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation
                let messageId = deeplink.customMetadata["messageId"] as? String 
                self.startConversationFlow(for: conversation, startingMessageId: messageId)
            } else if let connectionId = deeplink.customMetadata["connectionId"] as? String {

                guard let connection = ConnectionStore.shared.connections.first(where: { connection in
                    return connection.objectId == connectionId
                }), let identifier = connection.conversationId,
                       let conversationId = try? ChannelId.init(cid: identifier)  else {
                           return
                       }
                let conversation = ChatClient.shared.channelController(for: conversationId).conversation

                self.startConversationFlow(for: conversation, startingMessageId: nil)
            }

        default:
            break
        }
    }

    #warning("Remove after Beta")
    func createConversation() async {
        let channelId = ChannelId(type: .messaging, id: UUID().uuidString)

        do {
            let controller = try ChatClient.shared.channelController(createChannelWithId: channelId,
                                                                     name: nil,
                                                                     imageURL: nil,
                                                                     team: nil,
                                                                     members: [],
                                                                     isCurrentUserMember: true,
                                                                     messageOrdering: .bottomToTop,
                                                                     invites: [],
                                                                     extraData: [:])

            try await controller.synchronize()
            self.startConversationFlow(for: controller.conversation, startingMessageId: nil)
        } catch {
            print(error)
        }
    }
}

extension ArchiveCoordinator: ArchiveViewControllerDelegate {

    nonisolated func archiveView(_ controller: ArchiveViewController,
                                 didSelect item: ArchiveCollectionViewDataSource.ItemType) {

        Task.onMainActor {
            switch item {
            case .notice(let notice):
                self.handle(notice: notice)
            case .conversation(let conversationID):
                let conversation = ChatClient.shared.channelController(for: conversationID).conversation
                self.startConversationFlow(for: conversation, startingMessageId: nil)
            }
        }
    }

    func startConversationFlow(for conversation: Conversation?, startingMessageId: MessageId?) {
        self.removeChild()

        let coordinator = ConversationCoordinator(router: self.router,
                                                  deepLink: self.deepLink,
                                                  conversation: conversation,
                                                  startingMessageId: startingMessageId)
        self.addChildAndStart(coordinator, finishedHandler: { [unowned self] (_) in
            self.router.dismiss(source: self.archiveVC, animated: true)
        })
        self.router.present(coordinator,
                            source: self.router.topmostViewController,
                            cancelHandler: { [unowned self] in
            print("Did Cancel")
        })
    }

    private func handle(notice: SystemNotice) {
        switch notice.type {
        case .alert:
            if let conversationID = notice.attributes?["conversationId"] as? ChannelId {
                let conversation = ChatClient.shared.channelController(for: conversationID).conversation
                self.startConversationFlow(for: conversation, startingMessageId: nil)
            }
        case .connectionRequest:
            break
        case .connectionConfirmed:
            break
        case .messageRead:
            break
        case .system:
            break
        case .rsvps:
            self.startPeopleFlow()
        }
    }

    func startPeopleFlow() {
        self.removeChild()
        let coordinator = PeopleCoordinator(includeConnections: false,
                                            router: self.router,
                                            deepLink: self.deepLink)
        self.addChildAndStart(coordinator) { result in
            coordinator.toPresentable().dismiss(animated: true)
        }
        self.router.present(coordinator, source: self.archiveVC)
    }
}
