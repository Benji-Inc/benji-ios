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
                configuration.containingApplicationBundleIdentifier = "com.Jibber-Inc.iOS"
                configuration.server = Config.shared.environment.url
                configuration.applicationId = Config.shared.environment.appId
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
                    self.getUnreadMessagesNotice()
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
    
    func getUnreadMessagesNotice() {
        guard let query = Notice.query() else { return }
        query.whereKey("type", equalTo: Notice.NoticeType.unreadMessages.rawValue)
        do {
            if let notice = try? query.getFirstObject() as? Notice {
                self.scheduleUnreadMessagesNote(with: notice)
            }
        }
    }

    private func scheduleUnreadMessagesNote(with notice: Notice) {
        let content = UNMutableNotificationContent()
        let count = notice.unreadMessageIds.count
        
        logDebug(count)
        var title: String = ""
        var body: String = ""
        if count == 1 {
            title = "\(count) Unread Message"
            body = "You have \(count) unread message since your last vist."
        } else if count > 1 {
            title = "\(count) Unread Messages"
            body = "You have \(count) unread messages."
        } else {
            title = "All caught up"
            body = "You have 0 unread messages since your last visit."
        }
        content.title = title
        content.body = body
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: "unreadMessagesNotice",
                                            content: content,
                                            trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func testNote() {
        let content = UNMutableNotificationContent()
        
        content.title = "title"
        content.body = "Body"
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: "someText",
                                            content: content,
                                            trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
    }
}
