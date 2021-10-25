//
//  ChatChannel+Async.swift
//  ChatChannel+Async
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationController = ChatChannelController

extension ChatChannelController {

    var conversation: Conversation {
        return self.channel!
    }

    /// Loads previous messages from backend.
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` than the provided ID.
    ///   - limit: Limit for page size.
    func loadPreviousMessages(before messageId: MessageId? = nil, limit: Int = 25) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadPreviousMessages(before: messageId, limit: limit) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    @discardableResult
    func createNewMessage(with sendable: Sendable) async throws -> MessageId {
        switch sendable.kind {
        case .text(let text):
            return try await self.createNewMessage(text: text)
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

    /// Creates a new message locally and schedules it for send.
    ///
    /// - Parameters:
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - isSilent: A flag indicating whether the message is a silent message.
    ///     Silent messages are special messages that don't increase the unread messages count nor mark a channel as unread.
    ///   - attachments: An array of the attachments for the message.
    ///     `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    @discardableResult
    func createNewMessage(text: String,
                          pinning: MessagePinning? = nil,
                          isSilent: Bool = false,
                          attachments: [AnyAttachmentPayload] = [],
                          mentionedUserIds: [UserId] = [],
                          quotedMessageId: MessageId? = nil,
                          extraData: [String: RawJSON] = [:]) async throws -> MessageId {

        return try await withCheckedThrowingContinuation { continuation in
            self.createNewMessage(text: text,
                                  pinning: pinning,
                                  isSilent: isSilent,
                                  attachments: attachments,
                                  mentionedUserIds: mentionedUserIds,
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

    func editMessage(with sendable: Sendable) async throws {
        guard let messageID = sendable.previousMessage?.id else {
            throw(ClientError.apiError(detail: "No message id"))
        }

        switch sendable.kind {
        case .text(let text):
            return try await self.editMessage(messageID, text: text)
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

    /// Edits the specified message contained in this controller's channel with the provided value.
    ///
    /// - Parameters:
    ///   - text: The updated message text.
    func editMessage(_ messageID: MessageId, text: String) async throws {
        guard let channelID = self.cid else {
            throw(ClientError.apiError(detail: "No channel id"))
        }

        let messageController = self.client.messageController(cid: channelID, messageId: messageID)
        try await messageController.editMessage(text: text)
    }

    @discardableResult
    func createNewReply(for messageID: MessageId, with sendable: Sendable) async throws -> MessageId {
        switch sendable.kind {
        case .text(let text):
            return try await self.createNewReply(for: messageID, text: text)
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
    ///   - messageID: The id of the message we're replying to.
    ///   - text: Text of the message.
    ///   - pinning: Pins the new message. `nil` if should not be pinned.
    ///   - attachments: An array of the attachments for the message.
    ///    `Note`: can be built-in types, custom attachment types conforming to `AttachmentEnvelope` protocol
    ///     and `ChatMessageAttachmentSeed`s.
    ///   - showReplyInChannel: Set this flag to `true` if you want the message to be also visible in the channel, not only
    ///   in the response thread.
    ///   - quotedMessageId: An id of the message new message quotes. (inline reply)
    ///   - extraData: Additional extra data of the message object.
    ///   - completion: Called when saving the message to the local DB finishes.
    @discardableResult
    func createNewReply(for messageID: MessageId,
                        text: String,
                        pinning: MessagePinning? = nil,
                        attachments: [AnyAttachmentPayload] = [],
                        mentionedUserIds: [UserId] = [],
                        showReplyInChannel: Bool = false,
                        isSilent: Bool = false,
                        quotedMessageId: MessageId? = nil,
                        extraData: [String: RawJSON] = [:]) async throws -> MessageId {

        guard let channelID = self.cid else {
            throw(ClientError.apiError(detail: "No channel id"))
        }

        let messageController = self.client.messageController(cid: channelID, messageId: messageID)
        return try await messageController.createNewReply(text: text,
                                                          pinning: pinning,
                                                          attachments: attachments,
                                                          mentionedUserIds: mentionedUserIds,
                                                          showReplyInChannel: showReplyInChannel,
                                                          isSilent: isSilent,
                                                          quotedMessageId: quotedMessageId,
                                                          extraData: extraData)

    }

    /// Deletes the specified message that this controller manages.
    ///
    /// - Parameters:
    ///   - messageID: The id of the message to be deleted.
    func deleteMessage(_ messageID: MessageId) async throws {
        guard let channelID = self.cid else {
            throw(ClientError.apiError(detail: "No channel id"))
        }

        let messageController = self.client.messageController(cid: channelID, messageId: messageID)
        try await messageController.deleteMessage()
    }

    /// Deletes the specified message that this controller manages.
    ///
    /// - Parameters:
    ///   - messageID: The id of the message to be deleted.
    ///   - completion: The completion. Will be called on a **callbackQueue** when the network request is finished.
    ///                 If request fails, the completion will be called with an error.
    func deleteMessage(_ messageID: MessageId, completion: ((Error?) -> Void)? = nil) {
        guard let channelID = self.cid else {
            completion?(ClientError.apiError(detail: "No channel id"))
            return
        }

        let messageController = self.client.messageController(cid: channelID, messageId: messageID)
        messageController.deleteMessage(completion: completion)
    }

    /// Delete the channel this controller manages.
    func deleteChannel() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.deleteChannel { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
