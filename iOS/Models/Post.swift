//
//  Post.swift
//  Ours
//
//  Created by Benji Dodgson on 2/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum PostKey: String {
    case foo
}

final class Post: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }
}

extension Post: Objectable {
    typealias KeyType = PostKey

    func getObject<Type>(for key: PostKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: PostKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: PostKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
