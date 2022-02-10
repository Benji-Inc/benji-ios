//
//  ChatChannelMessage+Messageable.swift
//  ChatChannelMessage+Messageable
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias Message = ChatMessage

extension Message: Messageable {

    var conversationId: String {
        return self.cid?.description ?? String()
    }

    var isFromCurrentUser: Bool {
        return self.isSentByCurrentUser
    }

    var authorId: String {
        return self.author.id
    }

    var attributes: [String : Any]? {
        return nil
    }

    var avatar: Avatar {
        return self.author
    }

    var status: MessageStatus {
        return .sent
    }

    var context: MessageContext {
        if let value = self.extraData["context"],
           case RawJSON.string(let string) = value,
            let context = MessageContext.init(rawValue: string) {
            return context
        }
        return .respectful
    }
    
    var lastReadAt: Date? {
        let reads = self.latestReactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type == .read
        }.sorted { lhs, rhs in
            return lhs.createdAt < rhs.createdAt
        }
        
        return reads.first?.createdAt
    }

    var hasBeenConsumedBy: [Avatar] {
        let reads = self.latestReactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type == .read
        }

        return reads.compactMap { reaction in
            return reaction.author
        }
    }

    var kind: MessageKind {
        return .text(self.text)
    }

    var isDeleted: Bool {
        return self.type == .deleted
    }

    var totalReplyCount: Int {
        return self.replyCount
    }
    
    var recentReplies: [Messageable] {
        return self.latestReplies
    }

    func setToConsumed() async throws {
        let controller = ChatClient.shared.messageController(cid: self.cid!, messageId: self.id)
        try await controller.addReaction(with: .read)
        UserNotificationManager.shared.handleRead(message: self)
    }

    func setToUnconsumed() async throws {
        let controller = ChatClient.shared.messageController(cid: self.cid!, messageId: self.id)
        if let readReaction = self.latestReactions.first(where: { reaction in
            if let type = ReactionType(rawValue: reaction.type.rawValue), type == .read,
                reaction.author.userObjectId == User.current()?.objectId {
                return true
            }
            return false
        }) {
            try await controller.removeReaction(with: readReaction.type)
        }
    }
}

extension Message: MessageSequence {

    var streamCID: ConversationId? {
        return self.cid
    }

    var messages: [Messageable] {
        let messageArray = Array(ChatClient.shared.messageController(for: self)?.replies ?? [])
        return messageArray
    }
}
