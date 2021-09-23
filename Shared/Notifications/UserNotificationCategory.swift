//
//  UserNotificationCategory.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum UserNotificationCategory: String, CaseIterable {

    case connectionRequest = "connectionRequest"
    case connnectionConfirmed = "connectionConfirmed"

    var category: UNNotificationCategory {
        switch self {
        case .connectionRequest:
            return UNNotificationCategory(identifier: self.rawValue,
                                          actions: [], // Actions can be better handled on the extension
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        case .connnectionConfirmed:
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
        case .connnectionConfirmed:
            return [.sayHi]
        default:
            return []
        }
    }
}
