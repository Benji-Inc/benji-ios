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
        if let imageAttachment = self.imageAttachments.first {
            let attachment = PhotoAttachment(url: imageAttachment.imageURL,
                                             previewUrl: imageAttachment.imagePreviewURL,
                                             _data: nil,
                                             info: nil)
            return .photo(photo: attachment, body: self.text)
        } else if self.text.isSingleLink,
                  self.linkAttachments.count == 1,
                  let linkAttachment = self.linkAttachments.first {
            
            guard var urlComponents = URLComponents(url: linkAttachment.originalURL,
                                                    resolvingAgainstBaseURL: false) else {
                return .text(self.text)
            }
            
            // Make sure the url has a scheme.
            if urlComponents.scheme.isNil {
                urlComponents.scheme = "https"
            }
            
            guard let url = urlComponents.url else { return .text(self.text) }
            
            return .link(url: url, stringURL: self.text)
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
    
    var emotions: [Emotion] {
        let controller = ChatClient.shared.messageController(for: self)
        
        guard let data = controller?.message?.extraData["emotions"],
              case .array(let JSONObjects) = data else {
                  return []
              }
        
        let emotions: [Emotion] = JSONObjects.compactMap({ json in
            guard case .string(let value) = json else { return nil }
            return Emotion.init(rawValue: value)
        })
        
        return emotions
    }
    
    var expression: Emoji? {
        if let value = self.extraData["expression"],
           case RawJSON.string(let string) = value {
            return Emoji.init(with: string)
        }
        return nil
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
