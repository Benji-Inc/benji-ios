//
//  MessageContext.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UserNotifications

enum MessageContext: String, CaseIterable {

    case timeSensitive = "time-sensitive"
    case passive = "active"

    var color: ThemeColor {
        return .white 
    }

    var interruptionLevel: UNNotificationInterruptionLevel {
        switch self {
        case .timeSensitive:
            return .timeSensitive
        case .passive:
            return .passive
        }
    }

    var displayName: String {
        switch self {
        case .timeSensitive:
            return "Urgently"
        case .passive:
            return "Quietly"
        }
    }
}
