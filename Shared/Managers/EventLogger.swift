//
//  ParseEventLogger.swift
//  Jibber
//
//  Created by Martin Young on 1/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

class EventLogger {

    static func trackEvent(_ name: String) {
        let eventLog = EventLog(eventType: name)
        eventLog.saveEventually()
    }

    static func trackRemoteNotification(userInfo: [AnyHashable : Any]) {
        let eventLog = EventLog(eventType: "notification.remote")

        var payload: [String : Any] = [:]
        for kvp in userInfo {
            guard let key = kvp.key as? String else { break }
            payload[key] = kvp.value
        }
        eventLog.payload = payload

        eventLog.saveEventually()
    }
}
