//
//  ChatMessageController+Extensions.swift
//  ChatMessageController+Extensions
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias MessageController = ChatMessageController

extension MessageController {

    /// Creates a message controller using the shared ChatClient.
    static func controller(_ cid: ConversationId, messageId: MessageId) -> MessageController {
        return ChatClient.shared.messageController(cid: cid, messageId: messageId)
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

    func addReaction(with type: ReactionType, extraData: [String: RawJSON] = [:]) async {
        return await withCheckedContinuation({ continuation in
            let score: Int
            switch type {
            case .emotion(let emotion):
                guard let message = self.message else {
                    score = 0
                    break
                }
                score = (message.emotionCounts[emotion] ?? 0) + 1
            case .read:
                score = 0
            }

            self.addReaction(type.reaction,
                             score: score,
                             enforceUnique: false,
                             extraData: extraData) { error in
                if let e = error {
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
        switch sendable.kind {
        case .text(let text):
            return try await self.createNewReply(sendable: sendable, text: text)
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
        }

        throw(ClientError.apiError(detail: "Message type not supported."))
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
            if let expression = sendable.expression {
                data["expression"] = .string(expression.emoji)
            }
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
                    AnalyticsManager.shared.trackEvent(type: .replySent, properties: nil)
                    
                    Task {
                        await self.presentToast(for: sendable)
                    }
                    
                    continuation.resume(returning: messageId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func presentToast(for sendable: Sendable) async {
        
        switch sendable.deliveryType {
        case .timeSensitive:
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: self.messageId,
                                                             displayable: User.current()!,
                                                             title: "Time-Sensitive Message Delivered",
                                                             description: "Your message was successfully delivered and will attempt to notify all members of this thread. You will receive a notification once any member has read this message.",
                                                             deepLink: nil))
        case .conversational:
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: self.messageId,
                                                             displayable: User.current()!,
                                                             title: "Conversational Message Delivered ",
                                                             description: "Your message was successfully delivered and will attempt to notify all available members of this thread.",
                                                             deepLink: nil))
        case .respectful:
            break
        }
    }

    func loadPreviousReplies(including messageId: MessageId, limit: Int = 25) async throws {
        try await self.loadPreviousReplies(before: messageId, limit: limit)
        let controller = ChatClient.shared.messageController(cid: self.cid, messageId: messageId)
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
            self.deleteMessage { error in
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
