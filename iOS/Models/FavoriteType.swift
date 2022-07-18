//
//  UniqueExpression.swift
//  Jibber
//
//  Created by Benji Dodgson on 7/9/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum FavoriteType: CaseIterable {
    
    case agree
    case happy
    case surprised
    case sad
    case love
    case laughter
    
    var emotion: Emotion {
        switch self {
        case .agree:
            return .contentment
        case .happy:
            return .happy
        case .surprised:
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
//        let emotionCount: [String: Int] = [self.emotion.rawValue: 1]
//        let pairs: [String: AnyHashable] = ["author": User.current()!]

        return try await Expression.getObject(with: "Z2rwrGJyHn")
    }
}
