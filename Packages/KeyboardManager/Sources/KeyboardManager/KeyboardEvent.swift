//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/30/22.
//

import Foundation
import Combine

/// Keyboard events that can happen. Translates directly to `UIKeyboard` notifications from UIKit.
public enum KeyboardEvent {
    case willShow(NotificationCenter.Publisher.Output)
    case didShow(NotificationCenter.Publisher.Output)
    case willHide(NotificationCenter.Publisher.Output)
    case didHide(NotificationCenter.Publisher.Output)
    case willChangeFrame(NotificationCenter.Publisher.Output)
    case didChangeFrame(NotificationCenter.Publisher.Output)
    case none // No event has happened
    
    var name: String {
        switch self {
        case .willShow(_):
            return "willShow"
        case .didShow(_):
            return "didShow"
        case .willHide(_):
            return "willHide"
        case .didHide(_):
            return "didHide"
        case .willChangeFrame(_):
            return "willChangeFrame"
        case .didChangeFrame(_):
            return "didChangeFrame"
        case .none:
            return "none"
        }
    }
}
