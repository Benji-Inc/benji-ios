//
//  CircleGroup.swift
//  CircleGroup
//
//  Created by Benji Dodgson on 9/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum CircleGroupKey: String {
    case circles
    case name
}

final class CircleGroup: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var name: String? {
        get { self.getObject(for: .name) }
        set { self.setObject(for: .name, with: newValue) }
    }

    var userCount: Int {
        return 0
    }

    var circles: [Circle]? {
        get { self.getObject(for: .circles) }
    }

    func add(circle: Circle) {
        self.addUniqueObject(circle, forKey: CircleGroupKey.circles.rawValue)
    }

    func remove(circle: Circle) {
        self.remove(circle, forKey: CircleGroupKey.circles.rawValue)
    }
}

extension CircleGroup: Objectable {
    typealias KeyType = CircleGroupKey

    func getObject<Type>(for key: CircleGroupKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: CircleGroupKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: CircleGroupKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
