//
//  ChatChannel+Async.swift
//  ChatChannel+Async
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatChannelController {

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
}
