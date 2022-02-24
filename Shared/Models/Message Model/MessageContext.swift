//
//  MessageContext.swift
//  Benji
//
//  Created by Benji Dodgson on 6/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum MessageContext: String, CaseIterable {

    case timeSensitive = "time-sensitive"
    case conversational = "conversational"
    case respectful = "respectful"

    var color: ThemeColor {
        return .B1
    }

    var displayName: String {
        switch self {
        case .timeSensitive:
            return "Time Sensitive"
        case .conversational:
            return "Conversational"
        case .respectful:
            return "Small Talk"
        }
    }
    
    var description: String {
        switch self {
        case .timeSensitive:
            return "Notify no matter what"
        case .conversational:
            return "Notify if available"
        case .respectful:
            return "No need to notify"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .timeSensitive:
            return UIImage(systemName: "bell.badge")
        case .conversational:
            return UIImage(systemName: "bell")
        case .respectful:
            return UIImage(systemName: "bell.slash")
        }
    }
}
