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
            let message = self.getMessage(with: messageId) else { return }

        let memberIDs = conversation.lastActiveMembers.compactMap { member in
            return member.id
        }

//        let recipients = UserStore.shared.users.filter { user in
//            return memberIDs.contains(user.objectId ?? String())
//        }.compactMap { user in
//            return user.inPerson
//        }

        let incomingMessageIntent = INSendMessageIntent(recipients: nil,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: message.text,
                                                        speakableGroupName: conversation.speakableGroupName,
                                                        conversationIdentifier: conversationId,
                                                        serviceName: nil,
                                                        sender: nil, //message.createdBy,
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

    }

    private func getConversation(with identifier: String) -> ChatChannel? {
        return nil//ChatClient.shared.channelController(for: identifier).conversation
    }

    private func getMessage(with identifier: String) -> ChatMessage? {
        return nil
    }
}
