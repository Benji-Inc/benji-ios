//
//  User.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

enum ObjectKey: String {
    case objectId
    case createAt
    case updatedAt
}

enum UserKey: String {
    case email
    case reservation
    case connections
    case phoneNumber
    case givenName
    case familyName
    case smallImage
    case routine
}

final class User: PFUser {

    var phoneNumber: String? {
        get { return self.getObject(for: .phoneNumber) }
        set { self.setObject(for: .phoneNumber, with: newValue)}
    }

    var connections: [Connection] {
        return self.getObject(for: .connections) ?? []
    }

    var givenName: String {
        get { return String(optional: self.getObject(for: .givenName)) }
        set { self.setObject(for: .givenName, with: newValue) }
    }

    var familyName: String {
        get { return String(optional: self.getObject(for: .familyName)) }
        set { self.setObject(for: .familyName, with: newValue) }
    }

    var routine: Routine? {
        get { return self.getObject(for: .routine) }
        set { self.setObject(for: .routine, with: newValue) }
    }

    var smallImage: PFFileObject? {
        get { return self.getObject(for: .smallImage) }
        set { self.setObject(for: .smallImage, with: newValue) }
    }

    func add(conneciton: Connection) -> Future<Connection> {
        self.addUniqueObject(conneciton, forKey: UserKey.connections.rawValue)
        return self.saveLocalThenServer().transform { (_) in
            return conneciton
        }
    }

    func remove(conneciton: Connection) -> Future<Void> {
        self.remove(conneciton, forKey: UserKey.connections.rawValue)
        return self.saveLocalThenServer().asVoid()
    }
}
