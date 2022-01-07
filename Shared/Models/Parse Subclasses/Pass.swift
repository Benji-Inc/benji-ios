//
//  Pass.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum PassKey: String {
    case owner
    case attributes
    case connections
    case link
}

final class Pass: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var owner: User? {
        return self.getObject(for: .owner)
    }

    var attributes: [String: Any]? {
        return self.getObject(for: .attributes)
    }

    var connections: PFRelation<Connection>? {
        return self.getRelationalObject(for: .connections)
    }

    var link: String? {
        return self.getObject(for: .link)
    }
}

extension Pass: Objectable {

    typealias KeyType = PassKey

    func getObject<Type>(for key: PassKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: PassKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: PassKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

