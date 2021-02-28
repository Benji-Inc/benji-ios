//
//  UserNotificationAction.swift
//  Ours
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum UserNotificationAction: String {

    case acceptConnection
    case declineConnection

    var action: UNNotificationAction {
        switch self {
        case .acceptConnection:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Accept",
                                        options: [])
        case .declineConnection:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Decline",
                                        options: UNNotificationActionOptions.destructive)
        }
    }
}
