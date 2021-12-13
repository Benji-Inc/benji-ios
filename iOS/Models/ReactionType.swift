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

enum Emotion: String {
    case appreciation
    case amusement
    case anger
    case anxiety
    case awe
    case awkwardness
    case boredom
    case calmness
    case confusion
    case craving
    case disgust
    case empathy
    case entrancement
    case excitement
    case fear
    case horror
    case interest
    case joy
    case nostalgia
    case relief
    case romance
    case sadness
    case satisfaction
    case desire
    case suprise
    
    var emoji: String {
        switch self {
        case .appreciation:
            return "☺️"
        case .amusement:
            return "😂"
        case .anger:
            return "😡"
        case .anxiety:
            return "😓"
        case .awe:
            return "😳"
        case .awkwardness:
            return "🥴"
        case .boredom:
            return "🥱"
        case .calmness:
            return "😌"
        case .confusion:
            return "🤔"
        case .craving:
            return "😋"
        case .disgust:
            return "😖"
        case .empathy:
            return "😔"
        case .entrancement:
            return "🤪"
        case .excitement:
            return "🤩"
        case .fear:
            return "😰"
        case .horror:
            return "😱"
        case .interest:
            return "🧐"
        case .joy:
            return "🥳"
        case .nostalgia:
            return "🤠"
        case .relief:
            return "😅"
        case .romance:
            return "😍"
        case .sadness:
            return "😥"
        case .satisfaction:
            return "🥰"
        case .desire:
            return "😈"
        case .suprise:
            return "😮"
        }
    }
}
