//
//  FocusStatusIntentHandler.swift
//  Ours
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Intents
import Parse

class FocusIntentHandler: NSObject, INShareFocusStatusIntentHandling {

    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {

//        if let isFocused = intent.focusStatus?.isFocused, let current = User.current() {
//
//        }

        let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}

