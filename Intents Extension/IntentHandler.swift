//
//  IntentHandler.swift
//  Intents Extension
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Intents

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        print("########## INTENTS")
        switch intent {
            case is INSendMessageIntent, is INSearchForMessagesIntent, is INSetMessageAttributeIntent:
                return MessageIntentHandler()
            case is INShareFocusStatusIntent:
                return FocusIntentHandler()
            default:
                // SiriKit doesn't call this method with intents you don't support.
                return self
        }
    }
}
