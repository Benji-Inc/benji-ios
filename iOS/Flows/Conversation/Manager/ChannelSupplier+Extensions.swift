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

    func find(channelId: String) async throws -> TCHChannel {
        let channel: TCHChannel = try await withCheckedThrowingContinuation { continuation in
            guard let channels = ChatClientManager.shared.client?.channelsList() else {
                return continuation.resume(throwing: ClientError.message(detail: "No channels were found."))
            }

            channels.channel(withSidOrUniqueName: channelId) { (result, channel) in
                if let strongConversation = channel, result.isSuccessful() {
                    continuation.resume(returning: strongConversation)
                } else if let error = result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "No channel with that ID was found."))
                }
            }
        }

        return channel
    }

    func delete(channel: TCHChannel) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            channel.destroy { result in
                if result.isSuccessful() {
                    continuation.resume(returning: ())
                } else if let error = result.error {
                    if error.code == 50107 {
                        Task {
                            do {
                                try await self.leave(channel: channel)
                                continuation.resume(returning: ())
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to delete channel."))
                }
            }
        }
    }

    private func leave(channel: TCHChannel) async throws  {
        return try await withCheckedThrowingContinuation { continuation in
            channel.leave { result in
                if result.isSuccessful() {
                    continuation.resume(returning: ())
                } else if let error = result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to leave channel."))
                }
            }
        }
    }
}
