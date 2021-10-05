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
    case conversationSid
    case initialConversations
}

final class Connection: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    enum Status: String {
        case created 
        case invited
        case pending
        case accepted
        case declined
    }

    var status: Status? {
        guard let string: String = self.getObject(for: .status) else { return nil }
        return Status(rawValue: string)
    }

    var to: User? {
        return self.getObject(for: .to)
    }

    var from: User? {
        return self.getObject(for: .from)
    }

    var conversationId: String? {
        return self.getObject(for: .conversationSid)
    }

    var initialConversations: [String] {
        get { return self.getObject(for: .initialConversations) ?? [] }
        set { self.setObject(for: .initialConversations, with: newValue) }
    }

    var nonMeUser: User? {
        if self.to?.objectId == User.current()?.objectId {
            return self.from
        } else {
            return self.to
        }
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
