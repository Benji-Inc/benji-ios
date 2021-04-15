//
//  SystemComment.swift
//  Ours
//
//  Created by Benji Dodgson on 4/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

struct SystemComment: Commentable {

    var post: Post?
    var author: User?
    var body: String?
    var attributes: [String : AnyHashable]?
    var reply: Comment?
    var updateId: String?

    init(post: Post,
         body: String,
         attributes: [String: AnyHashable]?,
         reply: Comment?) {

        self.post = post 
        self.author = User.current()
        self.body = body
        self.attributes = attributes
        self.reply = reply
        self.updateId = UUID().uuidString
    }

    init(with post: Post, object: Sendable) {
        var body = String()
        if case MessageKind.text(let text) = object.kind {
            body = text 
        }
        self.init(post: post,
                  body: body,
                  attributes: [:],
                  reply: nil)
    }

    static func == (lhs: SystemComment, rhs: SystemComment) -> Bool {
        return lhs.author == rhs.author &&
            lhs.body == rhs.body &&
            lhs.attributes == rhs.attributes &&
            lhs.reply == rhs.reply &&
            lhs.updateId == rhs.updateId &&
            lhs.post == rhs.post
    }
}
