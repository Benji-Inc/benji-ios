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
    
    var emoji: String {
        switch self {
        case .agree:
            return "👍"
        case .happy:
            return "😄"
        case .surprised:
            return "😳"
        case .sad:
            return "😢"
        case .love:
            return "😍"
        case .laughter:
            return "😂"
        }
    }
    
    func getExpression() async throws -> Expression? {
        guard let all = try? await self.fetchAll() else { return nil }
        
        await all.asyncForEach { expression in
            _ = try? await expression.retrieveDataIfNeeded()
        }
        
        let first = all.first { expression in
            expression.emotionCounts.keys.contains(self.emotion)
        }

        return first
    }
    
    func fetchAll() async throws -> [Expression] {
        let objects: [Expression] = try await withCheckedThrowingContinuation { continuation in
            guard let query = Expression.query() else {
                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
                return
            }
            query.whereKey("author", equalTo: User.current()!)
            
            query.findObjectsInBackground { objects, error in
                if let objs = objects as? [Expression] {
                    continuation.resume(returning: objs)
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }

        return objects
    }
}
