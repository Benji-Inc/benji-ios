//
//  ChatMessageController+Extensions.swift
//  ChatMessageController+Extensions
//
//  Created by Martin Young on 9/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatMessageController {

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
    func createNewReply(text: String,
                        pinning: MessagePinning? = nil,
                        attachments: [AnyAttachmentPayload] = [],
                        mentionedUserIds: [UserId] = [],
                        showReplyInChannel: Bool = false,
                        isSilent: Bool = false,
                        quotedMessageId: MessageId? = nil,
                        extraData: [String: RawJSON] = [:]) async throws -> MessageId {

        return try await withCheckedThrowingContinuation { continuation in
            self.createNewReply(text: text,
                                pinning: pinning,
                                attachments: attachments,
                                mentionedUserIds: mentionedUserIds,
                                showReplyInChannel: showReplyInChannel,
                                isSilent: isSilent,
                                quotedMessageId: quotedMessageId,
                                extraData: extraData) { result in

                switch result {
                case .success(let messageID):
                    continuation.resume(returning: messageID)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
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
}
