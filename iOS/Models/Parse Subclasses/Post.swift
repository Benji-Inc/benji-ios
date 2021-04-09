//
//  Post.swift
//  Ours
//
//  Created by Benji Dodgson on 2/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

enum PostKey: String {
    case author = "author"
    case body = "body"
    case priority = "priority"
    case triggerDate = "triggerDate"
    case expirationDate = "expirationDate"
    case type = "type"
    case file = "file"
    case duration = "duration"
    case attributes = "attributes"
    case comments = "comments"
}

final class Post: PFObject, PFSubclassing, Postable, Subscribeable {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var author: User? {
        get { return self.getObject(for: .author) }
        set { self.setObject(for: .author, with: newValue) }
    }

    var body: String? {
        get { return self.getObject(for: .body) }
        set { self.setObject(for: .body, with: newValue) }
    }

    var priority: Int {
        get { return self.getObject(for: .priority) ?? self.type.defaultPriority }
        set { self.setObject(for: .priority, with: newValue) }
    }

    var triggerDate: Date? {
        get { return self.getObject(for: .triggerDate) }
        set { self.setObject(for: .triggerDate, with: newValue) }
    }

    var expirationDate: Date? {
        get { return self.getObject(for: .expirationDate) }
        set { self.setObject(for: .expirationDate, with: newValue) }
    }

    var type: PostType {
        get {
            guard let string: String = self.getObject(for: .type), let type = PostType(rawValue: string) else { fatalError("Unkown post type") }
            return type
        }
        set { self.setObject(for: .type, with: newValue.rawValue) }
    }

    var file: PFFileObject? {
        get { return self.getObject(for: .file) }
        set { self.setObject(for: .file, with: newValue) }
    }

    var attributes: [String : Any]? {
        get { return self.getObject(for: .attributes) }
        set { self.setObject(for: .attributes, with: newValue) }
    }

    var duration: Int {
        get { return self.getObject(for: .duration) ?? 5 }
        set { self.setObject(for: .duration, with: newValue) }
    }

    var comments: PFRelation<Comment>? {
        return self.getRelationalObject(for: .comments)
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
