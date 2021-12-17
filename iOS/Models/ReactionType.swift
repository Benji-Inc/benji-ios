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

enum Emotion: String, CaseIterable, Identifiable {
        
    case appreciation
    case amused
    case angry
    case anxious
    case awe
    case awkward
    case bored
    case calm
    case confused
    case craving
    case disgusted
    case empathetic
    case entrance
    case excited
    case fearful
    case horrorified
    case interested
    case joyful
    case nostalgic
    case relieved
    case romantic
    case sad
    case satisfied
    case desired
    case suprised
    
    var emoji: String {
        switch self {
        case .appreciation:
            return "☺️"
        case .amused:
            return "😂"
        case .angry:
            return "😡"
        case .anxious:
            return "😓"
        case .awe:
            return "😳"
        case .awkward:
            return "🥴"
        case .bored:
            return "🥱"
        case .calm:
            return "😌"
        case .confused:
            return "🤔"
        case .craving:
            return "😋"
        case .disgusted:
            return "😖"
        case .empathetic:
            return "😔"
        case .entrance:
            return "🤪"
        case .excited:
            return "🤩"
        case .fearful:
            return "😰"
        case .horrorified:
            return "😱"
        case .interested:
            return "🧐"
        case .joyful:
            return "🥳"
        case .nostalgic:
            return "🤠"
        case .relieved:
            return "😅"
        case .romantic:
            return "😍"
        case .sad:
            return "😥"
        case .satisfied:
            return "🥰"
        case .desired:
            return "😈"
        case .suprised:
            return "😮"
        }
    }
    
    var reaction: MessageReactionType {
        return MessageReactionType.init(stringLiteral: self.rawValue)
    }
    
    var id: Emotion { self }
}
