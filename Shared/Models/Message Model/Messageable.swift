//
//  Messageable.swift
//  Benji
//
//  Created by Benji Dodgson on 11/9/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

enum MessageStatus: String {
    case sent //Message was sent as a system message
    case delivered //Message was successfully delivered by Twilio
    case unknown
    case error
}

protocol Messageable {

    var id: String { get }
    var conversationId: String { get }
    var createdAt: Date { get }
    var isFromCurrentUser: Bool { get }
    var authorId: String { get }
    var attributes: [String: Any]? { get }
    var avatar: Avatar { get }
    var status: MessageStatus { get }
    var context: MessageContext { get }
    var canBeConsumed: Bool { get }
    var isConsumedByMe: Bool { get }
    var isConsumed: Bool { get }
    var hasBeenConsumedBy: [Avatar] { get }
    var color: ThemeColor { get }
    var kind: MessageKind { get }
    var isDeleted: Bool { get }
    var totalReplyCount: Int { get }
    var recentReplies: [Messageable] { get }

    func setToConsumed() async throws
    func setToUnconsumed() async throws
    func appendAttributes(with attributes: [String: Any]) async throws -> Messageable
}

func ==(lhs: Messageable, rhs: Messageable) -> Bool {
    guard type(of: lhs) == type(of: rhs) else { return false }
    return lhs.createdAt == rhs.createdAt
        && lhs.kind == rhs.kind
        && lhs.authorId == rhs.authorId
        && lhs.id == rhs.id
        && lhs.conversationId == rhs.conversationId
}

extension Messageable {

    var canBeConsumed: Bool {
        return self.context != .status && !self.isConsumedByMe
    }

    var isConsumed: Bool {
        return self.hasBeenConsumedBy.count > 0 
    }

    var isConsumedByMe: Bool {
        return self.hasBeenConsumedBy.contains { avatar in
            return avatar.userObjectId == User.current()?.objectId
        }
    }

    func appendAttributes(with attributes: [String: Any]) async throws -> Messageable {
        return self
    }

    var color: ThemeColor {
        if self.isFromCurrentUser {
            if self.context == .passive {
                return .lightGray
            } else {
                return self.context.color
            }
        } else {
            if self.context == .status {
                return self.context.color
            } else {
                return .clear
            }
        }
    }

    /// Returns the most recent reply to this message that is loaded or, if there are no replies, the message itself is returned.
    /// NOTE: If this message has not loaded its replies yet, the most recent reply will not be available and nil will be returned.
    var mostRecentMessage: Messageable? {
        if self.totalReplyCount == 0 {
            return self
        }

        return self.recentReplies.first
    }
}
