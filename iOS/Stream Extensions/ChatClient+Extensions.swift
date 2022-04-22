//
//  ChatClientManager.swift
//  ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ChatClient {

    /// A shared chat client singleton.
    static var shared: ChatClient!

    /// Returns true if the shared client is connected to the chat service.
    static var isConnected: Bool {
        return self.shared?.connectionStatus == .connected
    }
    
    static func connectAnonymousUser() async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId
        self.shared = ChatClient.init(config: config, tokenProvider: nil)
                
        return try await withCheckedThrowingContinuation({ continuation in
            ChatClient.shared.connectAnonymousUser { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: ())
                }
            }
        })
    }

    /// Initializes the shared chat client singleton.
    static func initialize(for user: User) async throws {
        if self.shared.isNil {
            return try await self.initializeChatClient(with: user)
        } else if let token = try? await self.getChatToken() {
            return try await self.shared.connectUser(with: token)
        } else {
            logDebug("Failed to initialize chat")
        }
    }

    /// Retrieves the token
    static func getChatToken() async throws -> Token {
        let string = try await GetChatToken().makeRequest()
        return try Token(rawValue: string)
    }

    /// Initializes the ChatClient with a configuration, retrieves and sets token, and connects the user
    private static func initializeChatClient(with user: User) async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId

        self.shared = ChatClient.init(config: config, tokenProvider: nil)
        let token = try await self.getChatToken()
        ChatClient.shared.setToken(token: token)
        try await ChatClient.shared.connectUser(with: token)
        _ = ConversationsManager.shared
    }

    private func connectUser(with token: Token) async throws {
        let userId = User.current()?.objectId ?? String() as UserId
        var userInfo = UserInfo(id: userId, name: nil, imageURL: nil, extraData: [:])
        userInfo = UserInfo(id: userId,
                            name: User.current()?.fullName,
                            imageURL: User.current()?.smallImage?.url,
                            extraData: [:])

        /// connect to chat
        return try await withCheckedThrowingContinuation { continuation in
            ChatClient.shared.connectUser(
                userInfo: userInfo,
                token: token,
                completion: { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            )
        }
    }

    /// Returns a ChatChannelListController synchronized using the provided query.
    func queryChannels(query: ChannelListQuery) async throws -> ChatChannelListController {
        let controller = self.channelListController(query: query)
        return try await withCheckedThrowingContinuation({ continuation in
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller)
                }
            }
        })
    }

    /// Returns a ChatChannelMemberListController synchronized with the members requested with the query.
    func queryMembers(query: ChannelMemberListQuery) async throws -> ChatChannelMemberListController {
        let controller = self.memberListController(query: query)
        return try await withCheckedThrowingContinuation({ continuation in
            controller.synchronize { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: controller)
                }
            }
        })
    }

    func messageController(for messageable: Messageable) -> MessageController? {
        guard let msg = messageable as? Message else { return nil }
        return self.messageController(cid: msg.cid!, messageId: msg.id)
    }

    func message(cid: ConversationId, id: MessageId) -> Message? {
        return self.messageController(cid: cid, messageId: id).message
    }
}
