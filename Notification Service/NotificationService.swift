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

        guard let conversationId = request.content.conversationId,
              let messageId = request.content.messageId else { return }

        self.initializeParse()
        self.initializeChat()

        guard let conversation = self.getConversation(with: conversationId),
              let message = self.getMessage(with: conversation.cid, messageId: messageId) else { return }

        let memberIDs = conversation.lastActiveMembers.compactMap { member in
            return member.id
        }

        let query = User.query()
        query?.whereKey("objectId", containedIn: memberIDs)
        query?.findObjectsInBackground(block: { objects, error in
            if let users = objects as? [User] {

                let recipients = users.filter { user in
                    return memberIDs.contains(user.objectId ?? String())
                }.compactMap { user in
                    return user.inPerson
                }

                let sender = users.first { user in
                    return user.objectId == message.author.id
                }?.inPerson

                let incomingMessageIntent = INSendMessageIntent(recipients: recipients,
                                                                outgoingMessageType: .outgoingMessageText,
                                                                content: message.text,
                                                                speakableGroupName: conversation.speakableGroupName,
                                                                conversationIdentifier: conversationId,
                                                                serviceName: nil,
                                                                sender: sender,
                                                                attachments: nil)

                let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
                interaction.direction = .incoming
                interaction.donate(completion: nil)

                do {
                    let messageContent = try request.content.updating(from: incomingMessageIntent)
                    contentHandler(messageContent)
                } catch {
                    print(error)
                }
            }
        })
    }

    private func initializeParse() {
        if Parse.currentConfiguration.isNil  {
            Parse.initialize(with: ParseClientConfiguration(block: { (configuration: ParseMutableClientConfiguration) -> Void in
                configuration.applicationGroupIdentifier = Config.shared.environment.groudID
                configuration.containingApplicationBundleIdentifier = "com.Jibber-Inc.Jibber"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }))
        }
    }

    private func initializeChat() {
        #warning("Initialize ChatClient")
    }

    private func getConversation(with identifier: String) -> ChatChannel? {
        return nil//ChatClient.shared.channelController(for: identifier).conversation
    }

    private func getMessage(with channelId: ChannelId, messageId: String) -> ChatMessage? {
        return nil//ChatClient.shared.messageController(cid: channelId, messageId: messageId)
    }
}
