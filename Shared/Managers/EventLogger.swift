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
        PFAnalytics.trackEvent(name)
    }

    static func trackRemoteNotification(userInfo: [AnyHashable : Any]) {
        var dimensions: [String : String] = [:]

        for kvp in userInfo {
            guard let key = kvp.key as? String, let value = kvp.value as? String else { break }
            dimensions[key] = value
        }

        // Send the dimensions to Parse along with the 'search' event
        PFAnalytics.trackEvent("notification.remote", dimensions: dimensions)
    }
}
