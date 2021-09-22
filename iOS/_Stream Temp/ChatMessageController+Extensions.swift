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
