//
//  SuggestedReply.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/24/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import UIKit

enum SuggestedReply: CaseIterable {
    
    case ok
    case noThanks
    case onMyWay
    case what
    case thanks
    case great
    case busy
    case emoji
    case other
    
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
            return "Other"
        }
    }
    
    var image: UIImage? {
        if self == .other {
            return UIImage(systemName: "arrowshape.turn.up.left")
        } else if self == .emoji {
            return UIImage(systemName: "face.smiling")
        }
        return nil
    }
    
    var emojiReactions: [String] {
        return ["❤️", "👍", "👎", "😂", "😳", "🤨"]
    }
}
