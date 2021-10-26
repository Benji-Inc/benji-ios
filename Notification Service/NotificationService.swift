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

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        guard let conversationId = request.content.conversationId else { return }

        self.initializeParse()
        self.initializeChat()

        guard let conversation = self.getConversation(with: conversationId) else { return }

        // Intialize Parse
        // Initialize Chat
        // Get conversation

//        let incomingMessageIntent = INSendMessageIntent(recipients: <#T##[INPerson]?#>,
//                                                        outgoingMessageType: <#T##INOutgoingMessageType#>,
//                                                        content: <#T##String?#>,
//                                                        speakableGroupName: <#T##INSpeakableString?#>,
//                                                        conversationIdentifier: <#T##String?#>,
//                                                        serviceName: <#T##String?#>,
//                                                        sender: <#T##INPerson?#>,
//                                                        attachments: <#T##[INSendMessageAttachment]?#>)
//
//        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
//        interaction.direction = .incoming
//        interaction.donate(completion: nil)
//
//        do {
//            let messageContent = try request.content.updating(from: incomingMessageIntent)
//            contentHandler(messageContent)
//        } catch {
//            print(error)
//        }
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
}
