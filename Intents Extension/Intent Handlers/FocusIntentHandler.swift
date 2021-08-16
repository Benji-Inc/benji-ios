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

    override init() {
        super.init()
        self.initializeParse()
    }

    private func initializeParse() {
        if Parse.currentConfiguration == nil  {
            let config = ParseClientConfiguration { configuration in
                configuration.applicationGroupIdentifier = "group.com.BENJI"
                configuration.containingApplicationBundleIdentifier = "com.Benji.Ours"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }
            
            Parse.initialize(with: config)
        }
    }

    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {

        if let isFocused = intent.focusStatus?.isFocused, let current = User.current() {

            current.focusStatus = isFocused ? "focused" : "available"
            current.saveToServerSync()
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

