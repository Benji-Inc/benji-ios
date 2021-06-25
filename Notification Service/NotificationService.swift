//
//  NotificationService.swift
//  NotificationService
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UserNotifications
import Intents

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {

        let user = User.current()

        let incomingMessageIntent = INSendMessageIntent(recipients: [],
                                                        outgoingMessageType: .unknown,
                                                        content: nil,
                                                        speakableGroupName: nil,
                                                        conversationIdentifier: nil,
                                                        serviceName: nil,
                                                        sender: nil,
                                                        attachments: [])

        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        do {
            let messageContent = try request.content.updating(from: incomingMessageIntent)
            contentHandler(messageContent)
        }
        catch {
            // Handle error
        }
    }

//    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//        self.contentHandler = contentHandler
//        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
//
//        if let bestAttemptContent = bestAttemptContent {
//            // Modify the notification content here...
//            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
//
//            contentHandler(bestAttemptContent)
//        }
//    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
