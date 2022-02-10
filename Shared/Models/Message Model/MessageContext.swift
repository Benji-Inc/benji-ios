//
//  MessageContext.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum MessageContext: String, CaseIterable {

    case timeSensitive = "time-sensitive"
    case respectful = "respectful"

    var color: ThemeColor {
        return .B1
    }

    var displayName: String {
        switch self {
        case .timeSensitive:
            return "Urgently"
        case .respectful:
            return "Quietly"
        }
    }
}
