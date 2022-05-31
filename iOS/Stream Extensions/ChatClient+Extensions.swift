//
//  ChatClientManager.swift
//  ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationsClient {
    
    static var shared = ConversationsClient()
    private var client: ChatClient?
    
    /// Returns true if the shared client is connected to the chat service.
    var isConnected: Bool {
        return self.client?.connectionStatus == .connected
    }
    
    /// Returns true if the shared client is connected to the chat service.
    var isConnectedToCurrentUser: Bool {
        return self.client?.currentUserId == User.current()?.objectId
    }
    
    func disconnect() {
        self.client?.disconnect()
    }
    
    func connectAnonymousUser() async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId
        self.client = ChatClient.init(config: config, tokenProvider: nil)
                
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
    func initialize(for user: User) async throws {
        if self.client.isNil {
            return try await self.initializeChatClient(with: user)
        } else if let token = try? await self.getChatToken() {
            return try await self.connectUser(with: token)
        } else {
            logDebug("Failed to initialize chat")
        }
    }
    
    /// Initializes the ChatClient with a configuration, retrieves and sets token, and connects the user
    private func initializeChatClient(with user: User) async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId

        self.client = ChatClient.init(config: config, tokenProvider: nil)
        let token = try await self.getChatToken()
        ChatClient.shared.setToken(token: token)
        try await self.connectUser(with: token)
        _ = ConversationsManager.shared
    }
    
    /// Retrieves the token
    private func getChatToken() async throws -> Token {
        let string = try await GetChatToken().makeRequest()
        return try Token(rawValue: string)
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
    
    func conversationController(for conversationId: String) -> ConversationController? {
        guard let cid = try? ChannelId(cid: conversationId) else { return nil }
        return self.client?.channelController(for: cid)
    }
    
    func messageController(for conversationId: String, id: String) -> MessageController? {
        guard let cid = try? ChannelId(cid: conversationId) else { return nil }
        return self.client?.messageController(cid: cid, messageId: id)
    }
    
    func messageController(for messageable: Messageable) -> MessageController? {
        guard let cid = try? ChannelId(cid: messageable.conversationId) else { return nil }
        return self.client?.messageController(cid: cid, messageId: messageable.id)
    }

    func message(conversationId: String, id: String) -> Messageable? {
        return self.messageController(for: conversationId, id: id)?.message
    }
}

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

    func messageController(for messageable: Messageable) -> MessageController? {
        guard let msg = messageable as? Message, let cid = msg.cid else { return nil }
        return self.messageController(cid: cid, messageId: msg.id)
    }

    func message(cid: ConversationId, id: MessageId) -> Message? {
        return self.messageController(cid: cid, messageId: id).message
    }
}
