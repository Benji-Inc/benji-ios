//
//  UserNotificationAction.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum UserNotificationAction: String {

    case accept = "accept"
    case decline = "decline"
    case sayHi = "sayhi"

    var action: UNNotificationAction {
        switch self {
        case .accept:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Accept",
                                        options: [])
        case .decline:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Decline",
                                        options: UNNotificationActionOptions.destructive)
        case .sayHi:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Say 👋",
                                        options: [])
        }
    }
}
