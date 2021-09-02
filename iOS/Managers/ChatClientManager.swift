//
//  ConversationManager.swift
//  Benji
//
//  Created by Benji Dodgson on 1/29/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse
import Combine

class ChatClientManager: NSObject {

    static let shared = ChatClientManager()
    var client: TwilioChatClient?

    @Published var clientSyncUpdate: TCHClientSynchronizationStatus? = nil
    @Published var clientUpdate: ChatClientUpdate? = nil
    @Published var channelSyncUpdate: ConversationSyncUpdate? = nil
    @Published var channelsUpdate: ConversationUpdate? = nil
    @Published var messageUpdate: MessageUpdate? = nil
    @Published var memberUpdate: ConversationMemberUpdate? = nil

    var isSynced: Bool {
        guard let client = self.client else { return false }
        if client.synchronizationStatus == .completed || client.synchronizationStatus == .channelsListCompleted {
            return true
        }

        return false
    }

    var isConnected: Bool {
        guard let client = self.client else { return false }
        return client.connectionState == .connected
    }

    func initialize(token: String) async throws {
        // Initialize the ConversationSupplier so it can listen to the client updates.
        _ = ConversationSupplier.shared

        let result: Void = try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            TwilioChatClient.chatClient(withToken: token,
                                        properties: nil,
                                        delegate: self,
                                        completion: { (result, client) in
                if let error = result.error {
                    continuation.resume(throwing: error)
                } else if let strongClient = client {
                    self.client = strongClient
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to initialize chat client."))
                }
            })
        })

        try Task.checkCancellation()

        return result
    }

    func update(token: String) async throws {
        guard let client = self.client else {
            throw ClientError.message(detail: "Chat client missing.")
        }

        let result: TCHResult = await client.updateToken(token)

        if result.isSuccessful() {
            return
        } else if let error = result.error {
            throw error
        } else {
            throw ClientError.message(detail: "Failed to update chat token.")
        }
    }
}
