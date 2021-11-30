//
//  ReactionType.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct ReactionSummary: Hashable {
    let type: ReactionType
    let count: Int 
}

enum ReactionType: String, CaseIterable {

    case like
    case love
    case dislike
    case read

    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }

    var emoji: String {
        switch self {
        case .like:
            return "👍"
        case .love:
            return "😍"
        case .dislike:
            return "👎"
        case .read:
            return ""
        }
    }
}
