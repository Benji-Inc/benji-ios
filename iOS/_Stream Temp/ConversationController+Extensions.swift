//
//  ChatChannel+Async.swift
//  ChatChannel+Async
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Intents
import Combine

typealias ConversationController = ChatChannelController

extension ConversationController {

    var conversation: Conversation {
        return self.channel!
    }

    /// Creates a conversation controller using the shared ChatClient.
    static func controller(_ cid: ConversationId,
                           channelListQuery: ChannelListQuery? = nil,
                           messageOrdering: MessageOrdering = .topToBottom) -> ConversationController {
        
        return ChatClient.shared.channelController(for: cid,
                                                      channelListQuery: channelListQuery,
                                                      messageOrdering: messageOrdering)
    }

    func getOldestUnreadMessage(withUserID userID: UserId) -> Message? {
        return self.conversation.getOldestUnreadMessage(withUserID: userID)
    }

    /// Loads previous messages from backend including the one specified.
    /// - Parameters:
    ///   - messageId: ID of the last fetched message. You will get messages `older` and including the provided ID.
    ///   - limit: Limit for page size.
    func loadPreviousMessages(including messageId: MessageId, limit: Int = 25) async throws {
        try await self.loadPreviousMessages(before: messageId, limit: limit)
        let controller = ChatClient.shared.messageController(cid: self.cid, messageId: messageId)
        if let messageBefore = self.messages.first(where: { message in
            return message.createdAt < controller.message!.createdAt
        }) {
            try await self.loadNextMessages(after: messageBefore.id, limit: 1)
        }
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

    /// Loads next messages from backend including the one specified.
    ///
    /// - Parameters:
    ///   - messageId: ID of the message we want to load. You will also get messages `newer` than the provided ID.
    ///   - limit: Limit for page size.
    func loadNextMessages(including messageId: MessageId, limit: Int = 25) async throws {
        try await self.loadNextMessages(after: messageId, limit: limit)

        // If we haven't loaded the specified message,
        // then it's the next message in the list so load one more.
        guard !self.messages.contains(where: { message in
            message.id == messageId
        }) else { return }

        try await self.loadPreviousMessages(limit: 1)
    }

    /// Loads next messages from backend.
    ///
    /// - Parameters:
    ///   - messageId: ID of the current first message. You will get messages `newer` than the provided ID.
    ///   - limit: Limit for page size.
    func loadNextMessages(after messageId: MessageId? = nil, limit: Int = 25) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadNextMessages(after: messageId, limit: limit) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Returns the most recently sent message from either the current user or from another user.
    func getMostRecentMessage(fromCurrentUser: Bool) -> Message? {
        let allMessages: [Message] = Array(self.messages)

        // Find the most recent message that was sent by the user.
        return allMessages.first { message in
            if fromCurrentUser {
                return message.isFromCurrentUser
            } else {
                return !message.isFromCurrentUser
            }
        }
    }

    func donateIntent(for sendable: Sendable) async {
        guard case MessageKind.text(let text) = sendable.kind else { return }
        let memberIDs = self.conversation.lastActiveMembers.compactMap { member in
            return member.personId
        }

        let recipients = PeopleStore.shared.usersArray.filter { user in
            return memberIDs.contains(user.objectId ?? String())
        }.compactMap { user in
            return user.iNPerson
        }

        let sender = recipients.first { inperson in
            return inperson.isMe
        }

        let intent = INSendMessageIntent(recipients: recipients,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: text,
                                         speakableGroupName: self.conversation.speakableGroupName,
                                         conversationIdentifier: self.conversation.cid.id,
                                         serviceName: nil,
                                         sender: sender,
                                         attachments: nil)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .outgoing
        try? await interaction.donate()
    }

    @discardableResult
    func createNewMessage(with sendable: Sendable) async throws -> MessageId {
        let messageBody: String
        var attachments: [AnyAttachmentPayload] = []

        switch sendable.kind {
        case .text(let text):
            messageBody = text
        case .photo(let item, let body):
            if let url = item.url {
                let attachement = try AnyAttachmentPayload(localFileURL: url,
                                                           attachmentType: .image,
                                                           extraData: nil)
                attachments.append(attachement)
            }
            messageBody = body
        case .link(_, let stringURL):
            // The link URL is automatically detected by stream and added as an attachment.
            // Removing extra whitespace and make links lower case.
            messageBody = stringURL.trimWhitespace().lowercased()
        case .attributedText, .video, .location, .emoji, .audio, .contact:
            throw(ClientError.apiError(detail: "Message type not supported."))
        }

        return try await self.createNewMessage(sendable: sendable,
                                               text: messageBody,
                                               attachments: attachments)
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
    func createNewMessage(sendable: Sendable,
                          text: String,
                          pinning: MessagePinning? = nil,
                          isSilent: Bool = false,
                          attachments: [AnyAttachmentPayload] = [],
                          mentionedUserIds: [UserId] = [],
                          quotedMessageId: MessageId? = nil,
                          extraData: [String: RawJSON] = [:]) async throws -> MessageId {

        return try await withCheckedThrowingContinuation { continuation in
            var data = extraData
            if let expression = sendable.expression {
                data["expression"] = .string(expression.emoji)
            }
            data["context"] = .string(sendable.deliveryType.rawValue)
            self.createNewMessage(text: text,
                                  pinning: pinning,
                                  isSilent: isSilent,
                                  attachments: attachments,
                                  mentionedUserIds: mentionedUserIds,
                                  quotedMessageId: quotedMessageId,
                                  extraData: data) { result in

                switch result {
                case .success(let messageID):
                    Task {
                        await self.donateIntent(for: sendable)
                        await self.presentToast(for: sendable, messageId: messageID)
                    }
                    AnalyticsManager.shared.trackEvent(type: .messageSent, properties: nil)
                    continuation.resume(returning: messageID)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func presentToast(for sendable: Sendable, messageId: String) async {
        
        switch sendable.deliveryType {
        case .timeSensitive:
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: self.conversation.id,
                                                             displayable: User.current()!,
                                                             title: "Time-Sensitive Message Delivered",
                                                             description: "Your message was successfully delivered and will attempt to notify all members of this conversation. You will receive a notification once any member has read this message.",
                                                             deepLink: nil))
        case .conversational:
            await ToastScheduler.shared.schedule(toastType: .basic(identifier: self.conversation.id,
                                                             displayable: User.current()!,
                                                             title: "Conversational Message Delivered ",
                                                             description: "Your message was successfully delivered and will attempt to notify all available members of this conversation.",
                                                             deepLink: nil))
        case .respectful:
            break
        }
    }

    func editMessage(with sendable: Sendable) async throws {
        guard let messageID = sendable.previousMessage?.id else {
            throw(ClientError.apiError(detail: "No message id"))
        }

        switch sendable.kind {
        case .text(let text):
            return try await self.editMessage(sendable: sendable,
                                              messageID: messageID,
                                              text: text)
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
    func editMessage(sendable: Sendable,
                     messageID: MessageId,
                     text: String) async throws {

        guard let channelID = self.cid else {
            throw(ClientError.apiError(detail: "No channel id"))
        }

        let messageController = self.client.messageController(cid: channelID, messageId: messageID)
        return try await withCheckedThrowingContinuation({ continuation in
            messageController.editMessage(text: text) { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    Task {
                        await self.donateIntent(for: sendable)
                    }
                    continuation.resume(returning: ())
                }
            }
        })
    }

    @discardableResult
    func createNewReply(for messageID: MessageId, with sendable: Sendable) async throws -> MessageId {
        switch sendable.kind {
        case .text(let text):
            return try await self.createNewReply(sendable: sendable,
                                                 messageID: messageID,
                                                 text: text)
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
    func createNewReply(sendable: Sendable,
                        messageID: MessageId,
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

        return try await withCheckedThrowingContinuation({ continuation in
            var data = extraData
            if let expression = sendable.expression {
                data["expression"] = .string(expression.emoji)
            }
            data["context"] = .string(sendable.deliveryType.rawValue)
            messageController.createNewReply(text: text,
                                             pinning: pinning,
                                             attachments: attachments,
                                             mentionedUserIds: mentionedUserIds,
                                             showReplyInChannel: showReplyInChannel,
                                             isSilent: isSilent,
                                             quotedMessageId: quotedMessageId,
                                             extraData: data) { result in
                switch result {
                case .success(let messageId):
                    Task {
                        await self.donateIntent(for: sendable)
                    }
                    AnalyticsManager.shared.trackEvent(type: .replySent, properties: nil)
                    continuation.resume(returning: messageId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
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
        messageController.deleteMessage(hard: true, completion: completion)
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

    /// Remove users to the channel as members.
    ///
    /// - Parameters:
    ///   - users: Users Id to remove from conversation.
    func removeMembers(userIds: Set<UserId>) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.removeMembers(userIds: userIds) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Hide the channel this controller manages from queryChannels for the user until a message is added.
    ///
    /// - Parameters:
    ///   - clearHistory: Flag to remove channel history (**false** by default)
    func hideChannel(clearHistory: Bool = false) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.hideChannel(clearHistory: clearHistory) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Removes hidden status for the channel this controller manages.
    func showChannel() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.showChannel { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Marks the channel as read.
    func markRead() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.markRead { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

extension ConversationController: MessageSequenceController {

    var streamCid: ConversationId? {
        return self.cid
    }

    var messageSequence: MessageSequence? {
        return self.conversation
    }

    var messageArray: [Messageable] {
        return Array(self.messages)
    }

    var messageSequenceChangePublisher: AnyPublisher<EntityChange<MessageSequence>, Never> {
        return self.channelChangePublisher.map { messageChange in
            let change: EntityChange<MessageSequence>

            switch messageChange {
            case .create(let conversation):
                change = EntityChange.create(conversation)
            case .update(let conversation):
                change = EntityChange.update(conversation)
            case .remove(let conversation):
                change = EntityChange.remove(conversation)
            }

            return change
        }.eraseToAnyPublisher()
    }
}
