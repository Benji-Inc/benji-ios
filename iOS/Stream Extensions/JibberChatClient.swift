//
//  ChatClientManager.swift
//  ChatClientManager
//
//  Created by Martin Young on 9/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class JibberChatClient {
    
    static var shared = JibberChatClient()
    private var client: ChatClient?
        
    /// Returns true if the shared client is connected to the chat service.
    var isConnected: Bool {
        return self.client?.connectionStatus == .connected
    }
    
    /// Returns true if the shared client is connected to the chat service.
    var isConnectedToCurrentUser: Bool {
        return self.client?.currentUserId == User.current()?.objectId
    }
    
    var currentUserController: CurrentChatUserController {
        return self.client!.currentUserController()
    }
    
    var eventsController: ChannelEventsController? {
        return self.client?.eventsController() as? ChannelEventsController
    }
    
    private var initializeTask: Task<Void, Error>?
    
    func disconnect() {
        self.client?.disconnect()
    }
    
    /// Initializes the shared chat client singleton.
    func initialize(for user: User) async throws {
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            try await initializeTask.value
            return
        }
        
        // Otherwise start a new initialization task and wait for it to finish.
        self.initializeTask = Task {
            if self.client.isNil {
                return try await self.initializeChatClient(with: user)
            } else if let token = try? await self.getChatToken() {
                return try await self.connectUser(with: token)
            } else {
                logDebug("Failed to initialize chat")
            }
        }
        
        do {
            try await self.initializeTask?.value
        } catch {
            // Dispose of the task because it failed, then pass the error along.
            self.initializeTask = nil
            throw error
        }
    }
    
    func registerPush(for token: Data) async {

        if self.client.isNil {
            do {
                try await self.initializeTask?.value
            } catch {
                logError(error)
            }
        }
        
        return await withCheckedContinuation { continuation in
            if let client = self.client {
                let device = PushDevice.apn(token: token)
                client.currentUserController().addDevice(device)
                continuation.resume(returning: ())
            } else {
                continuation.resume(returning: ())
            }
        }
    }
    
    func connectAnonymousUser() async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId
        self.client = ChatClient.init(config: config)
                
        return try await withCheckedThrowingContinuation({ continuation in
            self.client?.connectAnonymousUser { error in
                if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: ())
                }
            }
        })
    }
    
    /// Initializes the ChatClient with a configuration, retrieves and sets token, and connects the user
    private func initializeChatClient(with user: User) async throws {
        var config = ChatClientConfig(apiKey: .init(Config.shared.environment.chatAPIKey))
        config.applicationGroupIdentifier = Config.shared.environment.groupId

        self.client = ChatClient.init(config: config)
        let token = try await self.getChatToken()
        self.client?.setToken(token: token)
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
            self.client?.connectUser(
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
    
    func conversation(for conversationId: String) -> Conversation? {
        return self.conversationController(for: conversationId)?.conversation
    }
    
    func conversationController(query: ChannelListQuery) -> ChatChannelListController? {
        return self.client?.channelListController(query: query)
    }
    
    func conversationController(for conversationId: String) -> ConversationController? {
        guard let cid = try? ChannelId(cid: conversationId) else { return nil }
        return self.client?.channelController(for: cid)
    }
    
    func conversationController(for conversationId: String,
                                query: ChannelListQuery? = nil,
                                messageOrdering: MessageOrdering = .topToBottom) -> ConversationController? {
        guard let cid = try? ChannelId(cid: conversationId) else { return nil }
        return self.client?.channelController(for: cid,
                                              channelListQuery: query,
                                              messageOrdering: messageOrdering)
    }
    
    func conversationController(for query: ChannelQuery,
                                messageOrdering: MessageOrdering = .topToBottom) -> ConversationController? {
        return self.client?.channelController(for: query, messageOrdering: messageOrdering)
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
    
    func getPeople(for conversation: Conversation) async -> [PersonType] {
        var people: [PersonType] = []
        let nonMeMembers = conversation.lastActiveMembers.filter { member in
            return member.id != User.current()?.objectId
        }
        
        await nonMeMembers.userIDs.asyncForEach { userId in
            guard let person = await PeopleStore.shared.getPerson(withPersonId: userId) else { return }
            people.append(person)
        }
        
        await PeopleStore.shared.unclaimedReservations.asyncForEach { (reservationId, reservation) in
            guard reservation.conversationCid == conversation.cid.description,
                    let contactId = reservation.contactId else { return }

            guard let person = await PeopleStore.shared.getPerson(withPersonId: contactId) else { return }
            people.append(person)
        }
        
        return people
    }
    
    func createNewConversation(for moment: Moment) async throws {
        guard let momentId = moment.objectId else { throw ClientError.message(detail: "No moment for the conversation.")}
        // Give the moment id is unique, we use that set the conversationId for easy query. 
        let channelId = ChannelId(type: .custom("moment"), id: momentId)
        let userIDs = Set([User.current()!.objectId!])
        let controller = try self.client?.channelController(createChannelWithId: channelId,
                                                            name: nil,
                                                            imageURL: nil,
                                                            team: nil,
                                                            members: userIDs,
                                                            isCurrentUserMember: true,
                                                            messageOrdering: .bottomToTop,
                                                            invites: [],
                                                            extraData: [:])
        
        try await controller?.synchronize()
    }
    
    func createNewConversation() async throws -> Conversation? {
        let username = User.current()?.initials ?? ""
        let channelId = ChannelId(type: .messaging, id: username+"-"+UUID().uuidString)
        let userIDs = Set([User.current()!.objectId!])
        let controller = try self.client?.channelController(createChannelWithId: channelId,
                                                            name: nil,
                                                            imageURL: nil,
                                                            team: nil,
                                                            members: userIDs,
                                                            isCurrentUserMember: true,
                                                            messageOrdering: .bottomToTop,
                                                            invites: [],
                                                            extraData: [:])
        
        try await controller?.synchronize()
        AnalyticsManager.shared.trackEvent(type: .conversationCreated, properties: nil)
        return controller?.conversation
    }
}
