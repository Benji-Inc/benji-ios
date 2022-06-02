//
//  ChatMessageController+Extensions.swift
//  ChatMessageController+Extensions
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine

typealias MessageController = ChatMessageController

extension MessageController {
    
    /// Creates a message controller using the shared ChatClient.
    static func controller(for message: Messageable) -> MessageController {
        return self.controller(for: message.conversationId, messageId: message.id)
    }

    /// Creates a message controller using the shared ChatClient.
    static func controller(for conversationId: String, messageId: String) -> MessageController {
        return JibberChatClient.shared.messageController(for: conversationId, id: messageId)!
    }

    func editMessage(with sendable: Sendable) async throws {
        switch sendable.kind {
        case .text(let text):
            return try await self.editMessage(text: text)
        case .attributedText:
            break
        case .photo:
            break
        case .video:
            break
        case .location:
            break
        case .emoji:
            break
        case .audio:
            break
        case .contact:
            break
        case .link:
            break
        case .media:
            break 
        }

        throw(ClientError.apiError(detail: "Message type not supported."))
    }

    /// Edits the message this controller manages with the provided values.
    ///
    /// - Parameters:
    ///   - text: The updated message text.
    func editMessage(text: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.editMessage(text: text) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    /// Unpin the message this controller manages.
    ///
    func unpinMessage() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.unpin { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    /// Pin the message this controller manages with the provided values.
    ///
    func pinMessage() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.pin(MessagePinning.noExpiration) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func add(expression: Expression) async throws {
        
        let text = self.message?.text ?? ""
        var extraData = self.message?.extraData ?? [:]
        var expressions: [RawJSON] = []
        if let value = extraData["expressions"], case RawJSON.array(let array) = value {
            expressions = array
        }
        do {
            let saved = try await expression.saveToServer()
            
            let expressionDict: [String: RawJSON] = ["authorId": .string(User.current()!.objectId!),
                                                     "expressionId": .string(saved.objectId!)]
            expressions.append(.dictionary(expressionDict))
            
            extraData["expressions"] = .array(expressions)
        } catch {
            throw(ClientError.apiError(detail: "Error saving expression for message."))
        }
        
        return await withCheckedContinuation({ continuation in
            
            self.editMessage(text: text,
                             extraData: extraData) { error in
                
                if let e = error {
                    Task {
                        await ToastScheduler.shared.schedule(toastType: .error(e))
                    }
                    logError(e)
                } else {
                    Task {
                        let image = ImageSymbol.faceSmiling.image
                        await ToastScheduler.shared.schedule(toastType: .success(image, "Expression added"))
                    }
                }
                continuation.resume(returning: ())
            }
        })
    }

    func addReaction(with type: ReactionType, extraData: [String: RawJSON] = [:]) async {
        return await withCheckedContinuation({ continuation in
            let score: Int
            switch type {
            case .read:
                score = 0
            }

            self.addReaction(type.reaction,
                             score: score,
                             enforceUnique: false,
                             extraData: extraData) { error in
                if let e = error {
                    Task {
                        await ToastScheduler.shared.schedule(toastType: .error(e))
                    }
                    logError(e)
                }
                continuation.resume(returning: ())
            }
        })
    }

    func removeReaction(with type: MessageReactionType) async throws {
        return try await withCheckedThrowingContinuation({ continuation in
            self.deleteReaction(type) { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: ())
                }
            }
        })
    }

    @discardableResult
    func createNewReply(with sendable: Sendable) async throws -> MessageId {
        let messageBody: String
        var attachments: [AnyAttachmentPayload] = []
        var extraData: [String: RawJSON] = [:]

        switch sendable.kind {
        case .text(let text):
            messageBody = text
        case .photo(let item, let body):
            if let url = item.url {
                let imagePayload = ImageAttachmentPayload(title: "",
                                                          imageRemoteURL: url,
                                                          imagePreviewRemoteURL: item.previewURL,
                                                          extraData: nil)
                let attachment = AnyAttachmentPayload(payload: imagePayload)
                attachments.append(attachment)
            }
            messageBody = body
        case .video(video: let video, body: let body):
            if let url = video.url {
                let previewID = UUID().uuidString
                var videoData: [String: RawJSON] = [:]
                videoData["previewID"] = .string(previewID)
                let file = try AttachmentFile(url: url)
                let videoPayload = VideoAttachmentPayload(title: nil,
                                                          videoRemoteURL: url,
                                                          file: file,
                                                          extraData: videoData)
                let attachment = AnyAttachmentPayload(payload: videoPayload)
                attachments.append(attachment)
                
                if let previewURL = video.previewURL {
                    let imagePayload = ImageAttachmentPayload(title: "",
                                                              imageRemoteURL: previewURL,
                                                              imagePreviewRemoteURL: previewURL,
                                                              extraData: videoData)
                    let previewAttachement = AnyAttachmentPayload(payload: imagePayload)
                    attachments.append(previewAttachement)
                }
            }
            messageBody = body
        case .media(items: let media, body: let body):
            media.forEach { item in
                switch item.type {
                case .photo:
                    if let url = item.url, let attachment = try? AnyAttachmentPayload(localFileURL: url,
                                                                                      attachmentType: .image,
                                                                                      extraData: nil) {
                        
                        attachments.append(attachment)
                    }
                case .video:
                    if let url = item.url {
                        let previewID = UUID().uuidString
                        var videoData: [String: RawJSON] = [:]
                        videoData["previewID"] = .string(previewID)
                    
                        if let attachment = try? AnyAttachmentPayload(localFileURL: url,
                                                                      attachmentType: .video,
                                                                      extraData: videoData) {
                            attachments.append(attachment)
                        }
                        
                        if let previewURL = item.previewURL,
                            let previewAttachment = try? AnyAttachmentPayload(localFileURL: previewURL,
                                                                              attachmentType: .image,
                                                                              extraData: videoData) {
                            
                            attachments.append(previewAttachment)
                        }
                    }
                }
            }
            messageBody = body
        case .link(_, let stringURL):
            // The link URL is automatically detected by stream and added as an attachment.
            // Remove extra whitespace and make links lower case.
            messageBody = stringURL.trimWhitespace().lowercased()
        case .attributedText, .location, .emoji, .audio, .contact:
            throw(ClientError.apiError(detail: "Message type not supported."))
        }
        
        if let expression = sendable.expression {
            let expressionDict: [String: RawJSON] = ["authorId": .string(User.current()!.objectId!),
                                                     "expressionId": .string(expression.objectId!)]
            
            extraData = ["expressions" : .array([.dictionary(expressionDict)])]
            AchievementsManager.shared.createIfNeeded(with: .firstExpression)
        }

        return try await self.createNewReply(sendable: sendable,
                                             text: messageBody,
                                             attachments: attachments,
                                             extraData: extraData)
    }

    /// Creates a new reply message locally and schedules it for send.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - attachments: An array of the attachments for the message.
    ///    `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    func createNewReply(sendable: Sendable,
                        text: String,
                        pinning: MessagePinning? = nil,
                        attachments: [AnyAttachmentPayload] = [],
                        mentionedUserIds: [UserId] = [],
                        showReplyInChannel: Bool = false,
                        isSilent: Bool = false,
                        quotedMessageId: MessageId? = nil,
                        extraData: [String: RawJSON] = [:]) async throws -> MessageId {

        return try await withCheckedThrowingContinuation { continuation in
            var data = extraData
            data["context"] = .string(sendable.deliveryType.rawValue)
            
            self.createNewReply(text: text,
                                pinning: pinning,
                                attachments: attachments,
                                mentionedUserIds: mentionedUserIds,
                                showReplyInChannel: showReplyInChannel,
                                isSilent: isSilent,
                                quotedMessageId: quotedMessageId,
                                extraData: data) { result in

                switch result {
                case .success(let messageId):
                    continuation.resume(returning: messageId)

                    AnalyticsManager.shared.trackEvent(type: .replySent, properties: nil)
                    AchievementsManager.shared.createIfNeeded(with: .firstReply)
                    
                    Task {
                        await self.presentToast(for: sendable)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func presentToast(for sendable: Sendable) async {
        
        switch sendable.deliveryType {
        case .timeSensitive:
            await ToastScheduler.shared.schedule(toastType: .success(sendable.deliveryType.symbol.image, "Reply delivered. Will notify all members of this conversation."))
            
        case .conversational:
            await ToastScheduler.shared.schedule(toastType: .success(sendable.deliveryType.symbol.image, "Reply delivered. Will attempt to notify all members of this conversation."))
        case .respectful:
            break
        }
    }

    func loadPreviousReplies(including messageId: String, limit: Int = 25) async throws {
        try await self.loadPreviousReplies(before: messageId, limit: limit)
        let controller = MessageController.controller(for: self.cid.description, messageId: messageId)
        if let replyBefore = self.replies.first(where: { message in
            return message.createdAt < controller.message!.createdAt
        }) {
            try await self.loadNextReplies(after: replyBefore.id, limit: 1)
        }
    }

    /// Loads previous messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///     In case no replies are fetched you will get the first `limit` number of replies.
    ///   - limit: Limit for page size.
    func loadPreviousReplies(before messageId: MessageId? = nil, limit: Int = 25) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadPreviousReplies(before: messageId, limit: limit) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }


    /// Loads new messages from backend after and including the one specified..
    ///
    /// - Parameters:
    ///   - messageId: ID of the message we want to load. You will get also messages `newer` than the provided ID.
    ///   - limit: Limit for page size.
    func loadNextReplies(including messageId: MessageId, limit: Int = 25) async throws {
        try await self.loadNextReplies(after: messageId, limit: limit)

        // If we haven't loaded the specified message,
        // then it's the next message in the list so load one more.
        guard !self.replies.contains(where: { message in
            message.id == messageId
        }) else { return }

        try await self.loadPreviousReplies(limit: 1)
    }

    /// Loads new messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` then the provided ID.
    ///   - limit: Limit for page size.
    func loadNextReplies(after messageId: MessageId? = nil, limit: Int = 25) async throws{
        return try await withCheckedThrowingContinuation { continuation in
            self.loadNextReplies(after: messageId, limit: limit) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Deletes the message this controller manages.
    func deleteMessage() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.deleteMessage(hard: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Returns the most recently sent message from either the current user or from another user.
    /// This checks both replies and the original message.
    func getMostRecent(fromCurrentUser: Bool) -> Message? {
        var allMessages: [Message] = []
        allMessages.append(contentsOf: Array(self.replies))
        if let message = self.message {
            allMessages.append(message)
        }

        // Find the most recent message that was sent by the user.
        return allMessages.first { message in
            if fromCurrentUser {
                return message.isFromCurrentUser
            } else {
                return !message.isFromCurrentUser
            }
        }
    }
}

extension MessageController: MessageSequenceController {

    var conversationId: String? {
        return self.cid.description
    }

    var messageSequence: MessageSequence? {
        return self.message
    }

    var messageArray: [Messageable] {
        return Array(self.replies)
    }

    var messageSequenceChangePublisher: AnyPublisher<EntityChange<MessageSequence>, Never> {
        return self.messageChangePublisher.map { messageChange in
            let change: EntityChange<MessageSequence>

            switch messageChange {
            case .create(let message):
                change = EntityChange.create(message)
            case .update(let message):
                change = EntityChange.update(message)
            case .remove(let message):
                change = EntityChange.remove(message)
            }

            return change
        }.eraseToAnyPublisher()
    }

    var messagesChangesPublisher: AnyPublisher<[ListChange<ChatMessage>], Never> {
        return self.repliesChangesPublisher
    }
}
