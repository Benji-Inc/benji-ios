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
    
    var deliveryType: MessageDeliveryType {
        if let value = self.extraData["context"],
           case RawJSON.string(let string) = value,
           let context = MessageDeliveryType(rawValue: string) {
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
    
    var readReactions: [ChatMessageReaction] {
        return self.latestReactions.filter { reaction in
            guard let type = ReactionType(rawValue: reaction.type.rawValue) else { return false }
            return type == .read
        }
    }
    
    var hasBeenConsumedBy: [PersonType] {
        return self.readReactions.compactMap { reaction in
            return reaction.author
        }
    }
    
    var kind: MessageKind {
        if self.mediaItems.count > 1 {
            return .media(items: self.mediaItems, body: self.text)
        } else if let imageAttachment = self.photoAttachments.first {
            let attachment = PhotoAttachment(url: imageAttachment.imageURL,
                                             previewURL: nil,
                                             data: nil,
                                             info: nil)
            return .photo(photo: attachment, body: self.text)
        } else if let videoAttachment = self.videoAttachments.first {
            let previewURL = self.getPreviewURL(for: videoAttachment.extraData?["previewID"])
            let attachment = VideoAttachment(url: videoAttachment.videoURL,
                                             previewURL: previewURL,
                                             previewData: nil,
                                             data: nil,
                                             info: nil)
            return .video(video: attachment, body: self.text)
        } else if self.text.isSingleLink, var url = self.text.getURLs().first {
            // If the backend generated link attachments, then use those.
            if self.linkAttachments.count == 1, let linkAttachment = self.linkAttachments.first {
                url = linkAttachment.originalURL
            }
            
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
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
    
    var expressions: [ExpressionInfo] {
        guard let value = self.extraData["expressions"], case RawJSON.array(let array) = value else { return [] }
        
        var values: [ExpressionInfo] = []
        
        array.forEach { value in
            if case RawJSON.dictionary(let dict) = value,
                let authorValue = dict["authorId"], case RawJSON.string(let authorId) = authorValue,
               let expressionValue = dict["expressionId"], case RawJSON.string(let expressionId) = expressionValue {
                values.append(ExpressionInfo(authorId: authorId, expressionId: expressionId))
            }
        }
        
        return values 
    }
    
    static func message(with conversationId: String, messageId: MessageId) -> Messageable? {
        return MessageController.controller(for: conversationId, messageId: messageId)?.message
    }
    
    func setToConsumed() async {
        let controller = JibberChatClient.shared.messageController(for: self.conversationId, id: self.id)
        await controller?.addReaction(with: .read)
        UserNotificationManager.shared.handleRead(message: self)
        NoticeStore.shared.removeNoticeIfNeccessary(for: self)
    }
    
    func setToUnconsumed() async throws {
        let controller = JibberChatClient.shared.messageController(for: self.conversationId, id: self.id)
        if let readReaction = self.latestReactions.first(where: { reaction in
            if let type = ReactionType(rawValue: reaction.type.rawValue), type == .read,
               reaction.author.personId == User.current()?.objectId {
                return true
            }
            return false
        }) {
            try await controller?.removeReaction(with: readReaction.type)
        }
    }
}

extension Message: MessageSequence {
    
    var streamCID: ConversationId? {
        return self.cid
    }
    
    var messages: [Messageable] {
        let messageArray = Array(JibberChatClient.shared.messageController(for: self)?.replies ?? [])
        return messageArray
    }

    var title: String? {
        return nil
    }
}

// MARK: - Attachments

extension Message {
    
    var mediaItems: [MediaItem] {
        var all: [MediaItem] = self.imageAttachments.compactMap { attachment in
            guard !attachment.isExpression && !attachment.isPreview else { return nil }
            return PhotoAttachment(url: attachment.imageURL,
                                   previewURL: nil,
                                   data: nil,
                                   info: nil)
        }
        
        let videos: [MediaItem] = self.videoAttachments.compactMap { attachment in
            let previewURL = self.getPreviewURL(for: attachment.extraData?["previewID"])
            return VideoAttachment(url: attachment.videoURL,
                                   previewURL: previewURL,
                                   previewData: nil,
                                   data: nil,
                                   info: nil)
        }
        
        all.append(contentsOf: videos)
        return all
    }

    var photoAttachments: [ChatMessageImageAttachment] {
        let imageAttachments = self.imageAttachments

        return imageAttachments.filter { imageAttachment in
            return !imageAttachment.isExpression && !imageAttachment.isPreview
        }
    }

    var expressionImageAttachments: [ChatMessageImageAttachment] {
        let imageAttachments = self.imageAttachments

        return imageAttachments.filter { imageAttachment in
            return imageAttachment.isExpression
        }
    }
    
    func getPreviewURL(for previewID: RawJSON?) -> URL? {
        guard let first = self.imageAttachments.first(where: { attachment in
            if attachment.isPreview, let value = attachment.extraData?["previewID"] {
                return value == previewID
            }
            return false
        }) else { return nil }
        
        return first.imageURL
    }
}
