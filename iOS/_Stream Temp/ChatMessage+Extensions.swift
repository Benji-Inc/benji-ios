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
        return self.author.personId
    }

    var attributes: [String : Any]? {
        return nil
    }

    var person: PersonType? {
        return self.author
    }

    var deliveryStatus: DeliveryStatus {
        if let localState = self.localState {
            switch localState {
            case .pendingSend, .sending:
                return .sending
            case .sendingFailed, .deletingFailed:
                return .error
            case .pendingSync, .syncing, .syncingFailed, .deleting:
                break
            }
        }

        if self.isConsumed {
            return .read
        }

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
    
    var lastUpdatedAt: Date? {
        let reads = self.latestReactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type == .read
        }.sorted { lhs, rhs in
            return lhs.createdAt < rhs.createdAt
        }
        
        guard let latestRead = reads.last?.createdAt else {
            return self.createdAt
        }

        return latestRead
    }

    var hasBeenConsumedBy: [PersonType] {
        let reads = self.latestReactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type == .read
        }

        return reads.compactMap { reaction in
            return reaction.author
        }
    }

    var kind: MessageKind {
        if let key = self.attachmentCounts.keys.first {
            switch key {
            case AttachmentType.image:
                if let streamAttachement = self.imageAttachments.first {
                    let attachment = PhotoAttachment(url: streamAttachement.imageURL,
                                                     _data: nil,
                                                     info: nil)
                    return .photo(photo: attachment, body: self.text)
                }
                return .text(self.text)
            case AttachmentType.audio:
                break
            case AttachmentType.file:
                break
            case AttachmentType.giphy:
                break
            case AttachmentType.linkPreview:
                break
            default:
                return .text(self.text)
            }
        }
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

    var emotion: Emotion? {
        let controller = ChatClient.shared.messageController(for: self)

        guard let data = controller?.message?.extraData["emotions"] else {
            return nil
        }

        guard case .array(let JSONObjects) = data, let emotionJSON = JSONObjects.first else {
            return nil
        }

        guard case .string(let emotionString) = emotionJSON,
              let emotion = Emotion(rawValue: emotionString) else {
                  return nil
              }

        return emotion
    }

    static func message(with cid: ConversationId, messageId: MessageId) -> Message {
        return MessageController.controller(cid, messageId: messageId).message!
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
               reaction.author.personId == User.current()?.objectId {
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
