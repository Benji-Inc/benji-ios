//
//  TCHMessageExtension+Intents.swift
//  Ours
//
//  Created by Benji Dodgson on 6/25/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import TwilioChatClient

extension TCHMessage {

    var incomingIntent: INSendMessageIntent? {
        let intent = INSendMessageIntent(recipients: [],
                                         outgoingMessageType: .unknown,
                                         content: nil,
                                         speakableGroupName: nil,
                                         conversationIdentifier: nil,
                                         serviceName: nil,
                                         sender: nil,
                                         attachments: [])
        return intent
    }
}

