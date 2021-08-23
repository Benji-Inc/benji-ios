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
        guard let isFocused = intent.focusStatus?.isFocused, let currentUser = User.current() else { return }

        currentUser.focusStatus = isFocused ? .focused : .available

        Task {
            do {
                try await currentUser.saveToServer()

                let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
                completion(response)
            } catch {
                let response = INShareFocusStatusIntentResponse(code: .failure, userActivity: nil)
                completion(response)
            }
        }

    }
}
