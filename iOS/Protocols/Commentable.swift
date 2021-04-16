//
//  File.swift
//  Ours
//
//  Created by Benji Dodgson on 4/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol Commentable: Hashable {
    var post: Post? { get set }
    var created: Date? { get set }
    var isReply: Bool { get }
    var author: User? { get set }
    var body: String? { get set }
    var attributes: [String: AnyHashable]? { get set }
    var reply: Comment? { get set }
    var updateId: String? { get set }
}

extension Commentable {
    var isReply: Bool {
        return !self.reply.isNil
    }
}
