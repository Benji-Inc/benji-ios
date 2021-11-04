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

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        Task {
            await self.initializeParse()
            //try await self.initializeChat()
            await self.updateContent(with: request, contentHandler: contentHandler)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        print("WILL EXPIRE")
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

    private func initializeChat() async throws {
        guard let user = User.current(), !ChatClient.isConnected else { return }
        try await ChatClient.initialize(for: user)
    }

    private func updateContent(with request: UNNotificationRequest,
                               contentHandler: @escaping (UNNotificationContent) -> Void) async {

        guard let conversationId = request.content.conversationId,
              //let messageId = request.content.messageId,
              let authorId = request.content.author,
              //let cid = try? ChannelId.init(cid: conversationId),
              //let message = self.getMessage(with: cid, messageId: messageId),
              let author = try? await User.getObject(with: authorId).iNPerson else { return }

        var recipients: [INPerson] = []
        var conversation: ChatChannel? = nil
//        if let convo = await self.getConversation(with: conversationId) {
//            let memberIds = convo.lastActiveMembers.compactMap({ member in
//                return member.id
//            })
//
//            if let persons = try? await User.localThenNetworkArrayQuery(where: memberIds,
//                                                                           isEqual: true,
//                                                                                         container: .users).compactMap({ user in
//                return user.iNPerson
//            }) {
//                recipients = persons
//            }
//            conversation = convo
//        }

        let incomingMessageIntent = INSendMessageIntent(recipients: recipients,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: request.content.body,
                                                        speakableGroupName: conversation?.speakableGroupName,
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

    private func getConversation(with identifier: String) async -> ChatChannel? {
        do {
            let cid = try ChannelId.init(cid: identifier)
            let controller = ChatClient.shared.channelController(for: cid)
            return try await withCheckedThrowingContinuation({ continuation in
                controller.synchronize { error in
                    if let e = error {
                        continuation.resume(throwing: e)
                    } else {
                        continuation.resume(returning: controller.channel)
                    }
                }
            })
        } catch {
            return nil
        }
    }

    private func getMessage(with channelId: ChannelId, messageId: MessageId) -> ChatMessage? {
        return ChatClient.shared.messageController(cid: channelId, messageId: messageId).message
    }
}
