//
//  MessageContext.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

enum MessageContext: String, CaseIterable {

    case timeSensitive
    case passive
    case status

    var title: Localized {
        switch self {
        case .timeSensitive:
            return "Time-Sensitive ⏰"
        case .passive:
            return "Casual 😌"
        case .status:
            return ""
        }
    }

    var text: Localized {
        switch self {
        case .timeSensitive:
            return "Time-Sensitive"
        case .passive:
            return "Casual"
        case .status:
            return ""
        }
    }

    var color: Color {
        switch self {
        case .timeSensitive:
            return .orange
        case .passive:
            return .lightPurple
        case .status:
            return .background3
        }
    }
}
