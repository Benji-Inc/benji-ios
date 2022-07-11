//
//  UniqueExpression.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum UniqueExpression: CaseIterable {
    
    case agree
    case happy
    case suprised
    case sad
    case love
    case laughter
    
    var emotion: Emotion {
        switch self {
        case .agree:
            return .contentment
        case .happy:
            return .happy
        case .suprised:
            return .surprised
        case .sad:
            return .sad
        case .love:
            return .love
        case .laughter:
            return .joy
        }
    }
    
    func getExpression() async throws -> Expression? {
        let emotionCount: [String: Int] = [self.emotion.rawValue: 1]
        let pairs: [String: Any] = ["emotionCounts": emotionCount, "author": User.current()!]
        return try await Expression.getFirstObject(with: pairs)
    }
}
