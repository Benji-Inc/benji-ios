//
//  Notice.swift
//  Ours
//
//  Created by Benji Dodgson on 5/23/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum NoticeKey: String {
    case type
    case attributes
    case priority
}

final class Notice: PFObject, PFSubclassing, Subscribeable {

    enum NoticeType: String {
        case alert
        case connectionRequest
        case system
    }

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var type: NoticeType? {
        get { return self.getObject(for: .type) }
    }

    var attributes: [String: AnyHashable]? {
        get { self.getObject(for: .attributes) }
    }

    var priority: Int? {
        get { self.getObject(for: .priority) }
    }
}

extension Notice: Objectable {
    typealias KeyType = NoticeKey

    func getObject<Type>(for key: NoticeKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: NoticeKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: NoticeKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
