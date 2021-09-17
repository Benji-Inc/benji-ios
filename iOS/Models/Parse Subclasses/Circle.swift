//
//  File.swift
//  File
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum CircleKey: String {
    case users
    case name
    case type
}

final class Circle: PFObject, PFSubclassing {

    enum CircleType: String {
        case inner = "INNER"
        case outer = "OUTER"
    }

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var name: String? {
        get { self.getObject(for: .name) }
        set { self.setObject(for: .name, with: newValue) }
    }

    var type: CircleType? {
        get {
            guard let value: String = self.getObject(for: .type), let t = CircleType(rawValue: value) else { return nil }
            return t
        }
    }

    var users: [User]? {
        get { self.getObject(for: .users) }
    }
}

extension Circle: Objectable {
    typealias KeyType = CircleKey

    func getObject<Type>(for key: CircleKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: CircleKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: CircleKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
