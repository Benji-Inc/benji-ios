//
//  Conneciton.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum ConnectionKey: String {
    case status
    case to
    case from
    case toPhoneNumber
}

final class Connection: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    enum Status: String {
        case invited
        case pending
        case accepted
        case declined
    }

    //TODO: Remove the setters once the cloud functions are enabled. 
    var status: Status? {
        get {
            guard let string: String = self.getObject(for: .status) else { return nil }
            return Status(rawValue: string)
        }
        set { self.setObject(for: .status, with: newValue?.rawValue) }
    }

    var to: User? {
        get { return self.getRelationalObject(for: .to) }
        set { self.setObject(for: .to, with: newValue) }
    }

    var toPhoneNumber: String? {
        get { return self.getObject(for: .toPhoneNumber) }
        set { self.setObject(for: .toPhoneNumber, with: newValue) }
    }

    var from: User? {
        get { return self.getRelationalObject(for: .from) }
        set { self.setObject(for: .from, with: newValue) }
    }
}

extension Connection: Objectable {
    typealias KeyType = ConnectionKey

    func getObject<Type>(for key: ConnectionKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: ConnectionKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: ConnectionKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
