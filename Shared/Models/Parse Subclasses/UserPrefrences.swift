//
//  UserPrefrences.swift
//  Ours
//
//  Created by Benji Dodgson on 6/5/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

enum UserPrefrencesKey: String {
    case foo
}

final class UserPrefrences: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }
}

extension UserPrefrences: Objectable {
    typealias KeyType = UserPrefrencesKey

    func getObject<Type>(for key: UserPrefrencesKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: UserPrefrencesKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: UserPrefrencesKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

