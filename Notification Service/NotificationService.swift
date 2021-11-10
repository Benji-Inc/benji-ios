//
//  NotificationService.swift
//  NotificationService
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UserNotifications
import Intents
import StreamChat
import Parse
import Combine

class NotificationService: UNNotificationServiceExtension {

    private var cancellables = Set<AnyCancellable>()
    var contentHandler: ((UNNotificationContent) -> Void)?
    var request: UNNotificationRequest?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        self.contentHandler = contentHandler
        self.request = request

        Task {
            await self.initializeParse()
            if let client = self.getChatClient() {
                await self.updateContent(with: request,
                                         client: client,
                                         contentHandler: contentHandler)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
            let bestAttemptContent = request?.content.mutableCopy() as? UNMutableNotificationContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func initializeParse() async {
        return await withCheckedContinuation { continuation in
            if Parse.currentConfiguration.isNil  {
                let config = ParseClientConfiguration { configuration in
                    configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                    configuration.containingApplicationBundleIdentifier = "com.Jibber-Inc.Jibber"
                    configuration.server = Config.shared.environment.url
                    configuration.applicationId = Config.shared.environment.appID
                    configuration.isLocalDatastoreEnabled = true
                }

                Parse.initialize(with: config)
            }

            continuation.resume(returning: ())
        }
    }

    private func getChatClient() -> ChatClient? {
        guard let user = User.current() else { return nil }

        var config = ChatClientConfig(apiKey: .init("hvmd2mhxcres"))
        config.isLocalStorageEnabled = true
        config.applicationGroupIdentifier = Config.shared.environment.groupId

        let client = ChatClient(config: config)
        let token = Token.development(userId: user.objectId!)
        client.setToken(token: token)

        return client
    }

    private func updateContent(with request: UNNotificationRequest,
                               client: ChatClient,
                               contentHandler: @escaping (UNNotificationContent) -> Void) async {

        guard let content = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
                return
        }

        guard let conversationId = request.content.conversationId,
              let messageId = request.content.messageId,
              let authorId = request.content.author,
              let cid = try? ChannelId.init(cid: conversationId) else { return }

        async let conversation = try? self.getConversation(with: client, cid: cid)
        async let message = try? self.getMessage(with: client, cid: cid, messageId: messageId)
        async let author = try? User.getObject(with: authorId).iNPerson

        guard let conversation = await conversation,
              let message = await message,
                let author = await author else {
            return
        }

        let memberIds = conversation.lastActiveMembers.compactMap { member in
            return member.id
        }

        guard let recipients: [INPerson] = try? await User.fetchAndUpdateLocalContainer(where: memberIds, container: .users).compactMap({ user in
            return user.iNPerson
        }) else { return }

        //switch message.


        let incomingMessageIntent = INSendMessageIntent(recipients: recipients,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: request.content.body,
                                                        speakableGroupName: conversation.speakableGroupName,
                                                        conversationIdentifier: conversationId,
                                                        serviceName: nil,
                                                        sender: author,
                                                        attachments: nil)

        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .incoming

        do {
            try await interaction.donate()
            let messageContent = try request.content.updating(from: incomingMessageIntent)
            contentHandler(messageContent)
        } catch {
            print(error)
        }
    }

    private func getConversation(with client: ChatClient, cid: ChannelId) async throws -> ChatChannel? {
        return try await withCheckedThrowingContinuation({ continuation in
            let controller = client.channelController(for: cid)
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller.channel)
                }
            }
        })
    }

    private func getMessage(with client: ChatClient,
                            cid: ChannelId,
                            messageId: MessageId) async throws -> ChatMessage? {

        return try await withCheckedThrowingContinuation({ continuation in
            let controller = client.messageController(cid: cid, messageId: messageId)
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller.message)
                }
            }
        })
    }
}
