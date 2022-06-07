//
//  SuggestedReply.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum SuggestedReply: String, CaseIterable {
    
    case ok = "SUGGESTION_OK"
    case noThanks = "SUGGESTION_NOTHANKS"
    case onMyWay = "SUGGESTION_ONMYWAY"
    case what = "SUGGESTION_WHAT"
    case thanks = "SUGGESTION_THANKS"
    case great = "SUGGESTION_GREAT"
    case busy = "SUGGESTION_BUSY"
    case emoji = "SUGGESTION_EMOJI"
    case other = "SUGGESTION_OTHER"
    
    var text: String {
        switch self {
            
        case .noThanks:
            return "No thanks."
        case .ok:
            return "Ok"
        case .onMyWay:
            return "On my way!"
        case .what:
            return "What?"
        case .thanks:
            return "Thanks"
        case .great:
            return "Great!"
        case .busy:
            return "I'm busy"
        case .emoji:
            return "Emoji"
        case .other:
            return "Add Reply"
        }
    }
    
    var image: UIImage? {
        if self == .other {
            return ImageSymbol.arrowTurnUpLeft.image
        } else if self == .emoji {
            return ImageSymbol.faceSmiling.image
        }
        return nil
    }
    
    var emojiReactions: [String] {
        return ["❤️", "👍", "👎", "😂", "😳", "🤨"]
    }
    
    var action: UNNotificationAction? {
        if self != .emoji {
            
            var icon: UNNotificationActionIcon? = nil
            if self == .other {
                icon = UNNotificationActionIcon(systemImageName: "arrowshape.turn.up.left")
            } else if self == .emoji {
                icon = UNNotificationActionIcon(systemImageName: "face.smiling")
            }
            
            return UNNotificationAction(identifier: self.rawValue,
                                        title: self.text,
                                        options: .foreground,
                                        icon: icon)
        }
        
        return nil
    }
}
