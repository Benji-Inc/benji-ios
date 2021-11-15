//
//  ConversationListController+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationListController = ChatChannelListController
typealias ConversationListQuery = ChannelListQuery

extension ConversationListController {

    var conversations: [Conversation] {
        return Array(self.channels)
    }

    /// Loads next conversations from backend.
    ///
    /// - Parameters:
    ///   - limit: Limit for page size.
    func loadNextConversations(limit: Int? = nil) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.loadNextChannels(limit: limit) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

extension ConversationListController: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: ChatChannelListController, rhs: ChatChannelListController) -> Bool {
        return lhs === rhs
    }
}
