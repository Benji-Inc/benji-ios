//
//  SystemMessage.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import Combine

class SystemMessage: Messageable {

    var createdAt: Date
    var authorID: String
    var attributes: [String : Any]?
    var avatar: Avatar
    var context: MessageContext
    var isFromCurrentUser: Bool
    var status: MessageStatus
    var id: String
    var updateId: String? {
        if let updateId = self.attributes?["updateId"] as? Int {
            return String(updateId)
        }
        return self.attributes?["updateId"] as? String
    }
    var hasBeenConsumedBy: [String] {
        return self.attributes?["consumers"] as? [String] ?? []
    }
    var kind: MessageKind

    init(avatar: Avatar,
         context: MessageContext,
         isFromCurrentUser: Bool,
         createdAt: Date,
         authorId: String,
         status: MessageStatus,
         kind: MessageKind,
         id: String,
         attributes: [String: Any]?) {

        self.avatar = avatar
        self.context = context
        self.isFromCurrentUser = isFromCurrentUser
        self.createdAt = createdAt
        self.authorID = authorId
        self.status = status
        self.id = id
        self.attributes = attributes
        self.kind = kind
    }

    // Used for updating the read state of messages
    convenience init(with message: Messageable) {

        self.init(avatar: message.avatar,
                  context: message.context,
                  isFromCurrentUser: message.isFromCurrentUser,
                  createdAt: message.createdAt,
                  authorId: message.authorID,
                  status: message.status,
                  kind: message.kind,
                  id: message.id,
                  attributes: message.attributes)
    }

    @discardableResult
    func updateConsumers(with consumer: Avatar) async throws -> Messageable {
        let messageable: Messageable = try await withCheckedThrowingContinuation { continuation in
            if let identity = consumer.userObjectID, !self.hasBeenConsumedBy.contains(identity) {
                var consumers = self.hasBeenConsumedBy
                consumers.append(identity)
                self.attributes?["consumers"] = consumers
                continuation.resume(returning: self)
            } else {
                continuation.resume(throwing: ClientError.generic)
            }
        }
        return messageable
    }
}
