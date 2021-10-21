//
//  IntentHandler.swift
//  Intents Extension
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        switch intent {
            case is INSendMessageIntent, is INSearchForMessagesIntent, is INSetMessageAttributeIntent:
                return MessageIntentHandler()
            case is INShareFocusStatusIntent:
            // Notificaiton permissions must be enabled for this to fire
            // Communication Notifications and Siri entitlements must be enabled
            // Privacy statement in info plist
            // Focus authorization must be enabled
                return FocusIntentHandler()
            default:
                // SiriKit doesn't call this method with intents you don't support.
                return self
        }
    }
}
