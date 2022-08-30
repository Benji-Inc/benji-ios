//
//  UserNotificationCategory.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum UserNotificationCategory: String, CaseIterable {
    
    case connectionRequest = "connectionRequest"
    case connnectionConfirmed = "connectionConfirmed"
    case newMessage = "MESSAGE_NEW"
    case moment
    
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
                                          actions: [],
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        case .newMessage:
            let actions: [UNNotificationAction] = SuggestedReply.allCases.compactMap { suggestion in
                return suggestion.action
            }
            return UNNotificationCategory(identifier: self.rawValue,
                                          actions: actions,
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        case .moment:
            return UNNotificationCategory(identifier: self.rawValue,
                                          actions: [],
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        }
    }
}
