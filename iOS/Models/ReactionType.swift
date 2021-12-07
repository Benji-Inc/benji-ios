//
//  ReactionType.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/27/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

struct ReactionSummary: Hashable, Comparable {

    let type: ReactionType
    let count: Int

    static func < (lhs: ReactionSummary, rhs: ReactionSummary) -> Bool {
        return lhs.type.priority > rhs.type.priority
    }
}

enum ReactionType: String, CaseIterable {

    case like
    case love
    case dislike
    case read

    var priority: Int {
        switch self {
        case .like:
            return 0
        case .love:
            return 1
        case .dislike:
            return 2
        case .read:
            return 3
        }
    }

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
