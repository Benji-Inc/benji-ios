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

    case read
    
    var rawValue: String {
        switch self {
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
        } else {
            return nil
        }
    }
}

func == (lhs: ReactionType, rhs: ReactionType) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
