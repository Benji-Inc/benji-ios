//
//  Feed.swift
//  Ours
//
//  Created by Benji Dodgson on 3/8/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum FeedKey: String {
    case owner
    case posts
}

final class Feed: PFObject, PFSubclassing, Subscribeable {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var owner: User? {
        get { return self.getObject(for: .owner) }
    }

    var posts: PFRelation<Post>? {
        get { self.getRelationalObject(for: .posts) }
    }
}

extension Feed: Objectable {
    typealias KeyType = FeedKey

    func getObject<Type>(for key: FeedKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: FeedKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: FeedKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

