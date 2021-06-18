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
import Combine

class FocusIntentHandler: NSObject, INShareFocusStatusIntentHandling {

    private var cancellables = Set<AnyCancellable>()

    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {

        if let isFocused = intent.focusStatus?.isFocused, let current = User.current() {

            current.focusStatus = isFocused ? "focused" : "available"
            current.saveToServer()
                .sink { result in
                    let code: INShareFocusStatusIntentResponseCode
                    switch result {
                    case .finished:
                        code = .success
                    case .failure(_):
                        code = .failure
                    }
                    let response = INShareFocusStatusIntentResponse(code: code, userActivity: nil)
                    completion(response)
                } receiveValue: { _ in
                }.store(in: &self.cancellables)
        }
    }
}

