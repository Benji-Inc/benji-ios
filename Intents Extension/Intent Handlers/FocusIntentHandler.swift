//
//  FocusStatusIntentHandler.swift
//  Jibber
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
                configuration.applicationGroupIdentifier = Config.shared.environment.groupId
                configuration.containingApplicationBundleIdentifier = "com.Jibber-Inc.Jibber"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appID
                configuration.isLocalDatastoreEnabled = true
            }
            
            Parse.initialize(with: config)
        }
    }

    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {
        guard let isFocused = intent.focusStatus?.isFocused, let currentUser = User.current() else { return }

        let newStatus: FocusStatus = isFocused ? .focused : .available

        Task {
            do {
                if currentUser.focusStatus != newStatus, !isFocused {
                    if isFocused {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["focusTimeAvailable"])
                    } else {
                        try? await UNUserNotificationCenter.current().add(self.createIsAvailableRequest(for: currentUser))
                    }
                }

                currentUser.focusStatus = newStatus
                try await currentUser.saveLocalThenServer()

                let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
                completion(response)
            } catch {
                let response = INShareFocusStatusIntentResponse(code: .failure, userActivity: nil)
                completion(response)
            }
        }
    }

    private func createIsAvailableRequest(for user: User) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Available"
        content.body = "You are now available to chat."
        let request = UNNotificationRequest(identifier: "focusTimeAvailable",
                                            content: content,
                                            trigger: nil)
        return request
    }
}
