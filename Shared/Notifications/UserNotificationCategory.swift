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
                                          actions: [], // Actions can be better handled on the extension
                                          intentIdentifiers: [],
                                          hiddenPreviewsBodyPlaceholder: "",
                                          options: .customDismissAction)
        }
    }
}
