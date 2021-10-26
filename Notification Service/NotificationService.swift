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

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

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
}
