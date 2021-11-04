//
//  NotificationService.swift
//  NotificationService
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

//{
//    "aps" : {
//        "alert" : {
//            "title" : "Time-Sensitive",
//            "body" : "I'm a time sensitive notification"
//        }
//        "interruption-level" : "time-sensitive"
//    }
//}

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
            await self.initializeChat()
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

    private func initializeChat() async {
        guard let user = User.current(), !ChatClient.isConnected else { return }
        do {
            try await ChatClient.initialize(for: user)
        } catch {
            print(error)
        }
    }

    private func updateContent(with request: UNNotificationRequest,
                               contentHandler: @escaping (UNNotificationContent) -> Void) async {

        guard let conversationId = request.content.conversationId,
              let messageId = request.content.messageId,
              let authorId = request.content.author,
              let cid = try? ChannelId.init(cid: conversationId),
              let message = self.getMessage(with: cid, messageId: messageId),
              let author = try? await User.getObject(with: authorId).iNPerson else { return }

        let conversation = await self.getConversation(with: conversationId)
        let memberIds = conversation?.lastActiveMembers.compactMap({ member in
            return member.id
        }) ?? []

        var recipients: [INPerson] = []
        if let persons = try? await User.localThenNetworkArrayQuery(where: memberIds,
                                                                       isEqual: true,
                                                                                     container: .users).compactMap({ user in
            return user.iNPerson
        }) {
            recipients = persons
        }
        
        await withTaskGroup(of: User?.self) { group in
            for memberId in memberIds {
                group.addTask {
                    return try? await User.getObject(with: memberId)
                }

                for await user in group {
                    if let u = user, let inPerson = u.iNPerson {
                        recipients.append(inPerson)
                    }
                }
            }
        }

        let incomingMessageIntent = INSendMessageIntent(recipients: recipients,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: message.text,
                                                        speakableGroupName: conversation?.speakableGroupName,
                                                        conversationIdentifier: conversationId,
                                                        serviceName: "Jibber",
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
