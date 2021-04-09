//
//  Comment.swift
//  Ours
//
//  Created by Benji Dodgson on 4/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum CommentKey: String {
    case author
    case body
    case attributes
    case reply
}

final class Comment: PFObject, PFSubclassing, Subscribeable {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var isReply: Bool {
        return !self.reply.isNil
    }

    var author: User? {
        get { return self.getObject(for: .author) }
        set { self.setObject(for: .author, with: newValue) }
    }

    var body: String? {
        get { return self.getObject(for: .body) }
        set { self.setObject(for: .body, with: newValue) }
    }

    var attributes: [String: Any]? {
        get { return self.getObject(for: .attributes) }
        set { self.setObject(for: .attributes, with: newValue) }
    }

    var reply: Comment? {
        get { return self.getObject(for: .reply) }
        set { self.setObject(for: .reply, with: newValue) }
    }
}

extension Comment: Objectable {
    typealias KeyType = CommentKey

    func getObject<Type>(for key: CommentKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: CommentKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: CommentKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
