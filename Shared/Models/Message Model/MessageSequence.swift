//
//  MessageSequence.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageSequence {

    var id: String { get }
    var conversationId: String { get }
    var createdAt: Date { get }
    var updateAt: Date { get }
    var isCreatedByCurrentUser: Bool { get }
    var authorID: String { get }
    var attributes: [String: Any]? { get }
    var messages: [Messageable] { get }
}

func ==(lhs: MessageSequence, rhs: MessageSequence) -> Bool {
    guard type(of: lhs) == type(of: rhs) else { return false }
    return lhs.id == rhs.id
        && lhs.conversationId == rhs.conversationId
        && lhs.createdAt == rhs.createdAt
        && lhs.updateAt == rhs.updateAt
        && lhs.authorID == rhs.authorID
}

extension MessageSequence {

    var isCreatedByCurrentUser: Bool {
        guard let user = User.current() else { return false }
        return user.objectId == self.authorID
    }
}
