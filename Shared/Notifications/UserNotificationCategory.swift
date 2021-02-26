//
//  UserNotificationCategory.swift
//  Ours
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum UserNotificationCategory: String, CaseIterable {

    case connectionRequest

    var category: UNNotificationCategory {
        switch self {
        case .connectionRequest:
            return UNNotificationCategory(identifier: self.rawValue,
                                          actions: self.actions.map({ userAction in
                                            return userAction.action
                                          }),
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        }
    }

    var actions: [UserNotificationAction] {
        switch self {
        case .connectionRequest:
            return [.acceptConnection, .declineConnection]
        }
    }
}

enum UserNotificationAction: String {

    case acceptConnection
    case declineConnection

    var action: UNNotificationAction {
        switch self {
        case .acceptConnection:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Accept",
                                        options: UNNotificationActionOptions(rawValue: 0))
        case .declineConnection:
            return UNNotificationAction(identifier: self.rawValue,
                                        title: "Decline",
                                        options: UNNotificationActionOptions(rawValue: 0))
        }
    }
}
