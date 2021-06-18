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

    case emergency
    case timeSensitive
    case convenient
    case passive
    case status

    var title: Localized {
        switch self {
        case .emergency:
            return "Important 🚨"
        case .timeSensitive:
            return "Time-Sensitive ⏰"
        case .convenient:
            return "When you have time 🙋🏻‍♂️"
        case .passive:
            return "Casual 😌"
        case .status:
            return ""
        }
    }

    var text: Localized {
        switch self {
        case .emergency:
            return "Emergency"
        case .timeSensitive:
            return "Time-Sensitive"
        case .convenient:
            return "When you have time"
        case .passive:
            return "Casual"
        case .status:
            return ""
        }
    }

    var color: Color {
        switch self {
        case .emergency:
            return .red
        case .timeSensitive:
            return .orange
        case .convenient:
            return .green
        case .passive:
            return .lightPurple
        case .status:
            return .background3
        }
    }
}
