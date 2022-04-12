//
//  ReactionType.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/11/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

enum ReactionType {

    case emotion(Emotion)
    case read
    
    var rawValue: String {
        switch self {
        case .emotion(let emotion):
            return emotion.rawValue
        case .read:
            return "read"
        }
    }

    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }
    
    init?(rawValue: String) {
        if rawValue == "read" {
            self = .read
        } else if let e = Emotion.init(rawValue: rawValue) {
            self = .emotion(e)
        } else {
            return nil
        }
    }
}

func == (lhs: ReactionType, rhs: ReactionType) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
