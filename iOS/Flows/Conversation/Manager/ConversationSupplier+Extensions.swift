//
//  ConversationSupplier+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TwilioChatClient

extension ConversationSupplier {

    func find(conversationId: String) async throws -> TCHChannel {
        let conversation: TCHChannel = try await withCheckedThrowingContinuation { continuation in
            guard let conversations = ChatClientManager.shared.client?.conversationsList() else {
                return continuation.resume(throwing: ClientError.message(detail: "No conversations were found."))
            }

            conversations.conversation(withSidOrUniqueName: conversationId) { (result, conversation) in
                if let strongConversation = conversation, result.isSuccessful() {
                    continuation.resume(returning: strongConversation)
                } else if let error = result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "No conversation with that ID was found."))
                }
            }
        }

        return conversation
    }

    func delete(conversation: TCHChannel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            conversation.destroy { result in
                if result.isSuccessful() {
                    continuation.resume(returning: ())
                } else if let error = result.error {
                    if error.code == 50107 {
                        Task {
                            do {
                                try await self.leave(conversation: conversation)
                                continuation.resume(returning: ())
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to delete conversation."))
                }
            }
        }
    }

    private func leave(conversation: TCHChannel) async throws  {
        return try await withCheckedThrowingContinuation { continuation in
            conversation.leave { result in
                if result.isSuccessful() {
                    continuation.resume(returning: ())
                } else if let error = result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to leave conversation."))
                }
            }
        }
    }
}
