//
//  SystemComment.swift
//  Ours
//
//  Created by Benji Dodgson on 4/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct SystemComment: Commentable, Comparable {

    var created: Date?
    var post: Post?
    var author: User?
    var body: String?
    var attributes: [String : AnyHashable]?
    var reply: Comment?
    var updateId: String?

    init(createdAt: Date?,
         updateId: String?,
         author: User?,
         post: Post,
         body: String,
         attributes: [String: AnyHashable]?,
         reply: Comment?) {

        self.created = createdAt
        self.post = post 
        self.author = author
        self.body = body
        self.attributes = attributes
        self.reply = reply
        self.updateId = updateId
    }

    init(with post: Post, object: Sendable) {
        var body = String()
        if case MessageKind.text(let text) = object.kind {
            body = text 
        }

        self.init(createdAt: Date(),
                  updateId: UUID().uuidString,
                  author: User.current(),
                  post: post,
                  body: body,
                  attributes: [:],
                  reply: nil)
    }

    init(with comment: Comment) {

        self.init(createdAt: comment.createdAt,
                  updateId: comment.updateId,
                  author: comment.author,
                  post: comment.post!,
                  body: String(optional: comment.body),
                  attributes: comment.attributes,
                  reply: comment.reply)
    }

    static func == (lhs: SystemComment, rhs: SystemComment) -> Bool {
        return lhs.author == rhs.author &&
            lhs.reply == rhs.reply &&
            lhs.updateId == rhs.updateId &&
            lhs.post == rhs.post &&
            lhs.created == rhs.created
    }

    static func < (lhs: SystemComment, rhs: SystemComment) -> Bool {
        return lhs.created! < rhs.created!
    }
}
