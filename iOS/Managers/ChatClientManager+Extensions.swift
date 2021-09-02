//
//  ConversationManager+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 4/27/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

typealias CompletionHandler = (_ success: Bool, _ error: Error?) -> Void

struct ChatClientUpdate {
    var client: TwilioChatClient
    var status: Status

    enum Status {
        case connectionState(TCHClientConnectionState)
        case userUpdate(TCHUser, TCHUserUpdate)
        case toastSubscribed
        case toastRegistrationFailed(TCHError)
        case error(TCHError)
    }
}

struct ConversationUpdate {
    var conversation: TCHChannel
    var status: Status

    enum Status {
        case added
        case changed
        case deleted
    }
}

struct ConversationSyncUpdate {
    var conversation: TCHChannel
    var status: TCHChannelSynchronizationStatus
}

struct MessageUpdate {
    var conversation: TCHChannel
    var message: TCHMessage
    var status: Status

    enum Status {
        case added
        case changed
        case deleted
        case toastReceived
    }
}

struct ConversationMemberUpdate {
    
    var conversation: TCHChannel
    var member: TCHMember
    var status: Status

    enum Status {
        case joined
        case left
        case changed
        case typingEnded
        case typingStarted
    }
}

extension ChatClientManager: TwilioChatClientDelegate {

    //MARK: CLIENT UDPATES

    func chatClientTokenExpired(_ client: TwilioChatClient) {
        Task { await self.getNewChatToken() }
    }

    func chatClientTokenWillExpire(_ client: TwilioChatClient) {
        Task { await self.getNewChatToken() }
    }

    private func getNewChatToken() async {
        do {
            let token = try await GetChatToken().makeRequest()
            try await self.update(token: token)
        } catch {
            print(error)
        }
    }

    func chatClient(_ client: TwilioChatClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        self.clientSyncUpdate = status
    }

    func chatClient(_ client: TwilioChatClient, connectionStateUpdated state: TCHClientConnectionState) {
        self.clientUpdate = ChatClientUpdate(client: client, status: .connectionState(state))
    }

    func chatClient(_ client: TwilioChatClient, user: TCHUser, updated: TCHUserUpdate) {
        self.clientUpdate = ChatClientUpdate(client: client, status: .userUpdate(user, updated))
    }

    func chatClientToastSubscribed(_ client: TwilioChatClient!) {
        self.clientUpdate = ChatClientUpdate(client: client, status: .toastSubscribed)
    }

    func chatClient(_ client: TwilioChatClient!, toastRegistrationFailedWithError error: TCHError!) {
        self.clientUpdate = ChatClientUpdate(client: client, status: .toastRegistrationFailed(error))
    }

    func chatClient(_ client: TwilioChatClient, errorReceived error: TCHError) {
        self.clientUpdate = ChatClientUpdate(client: client, status: .error(error))
    }

    //MARK: CHANNEL UPDATES

    func chatClient(_ client: TwilioChatClient, conversationAdded conversation: TCHChannel) {
        self.conversationsUpdate = ConversationUpdate(conversation: conversation, status: .added)
    }

    func chatClient(_ client: TwilioChatClient!, conversationChanged conversation: TCHChannel!) {
        self.conversationsUpdate = ConversationUpdate(conversation: conversation, status: .changed)
    }

    func chatClient(_ client: TwilioChatClient, conversationDeleted conversation: TCHChannel) {
        self.conversationsUpdate = ConversationUpdate(conversation: conversation, status: .deleted)
    }

    func chatClient(_ client: TwilioChatClient, conversation: TCHChannel, synchronizationStatusUpdated status: TCHChannelSynchronizationStatus) {
        self.conversationSyncUpdate = ConversationSyncUpdate(conversation: conversation, status: status)
    }

    //MARK: MEMBER UDPATES

    func chatClient(_ client: TwilioChatClient, conversation: TCHChannel, memberLeft member: TCHMember) {
        self.memberUpdate = ConversationMemberUpdate(conversation: conversation, member: member, status: .left)
        self.handle(member: member, in: conversation, status: .left)
    }

    func chatClient(_ client: TwilioChatClient, conversation: TCHChannel, memberJoined member: TCHMember) {
        self.memberUpdate = ConversationMemberUpdate(conversation: conversation, member: member, status: .joined)
        self.handle(member: member, in: conversation, status: .left)
    }

    func chatClient(_ client: TwilioChatClient!, conversation: TCHChannel!, memberChanged member: TCHMember!) {
        self.memberUpdate = ConversationMemberUpdate(conversation: conversation, member: member, status: .changed)
    }

    func chatClient(_ client: TwilioChatClient, typingEndedOn conversation: TCHChannel, member: TCHMember) {
        self.memberUpdate = ConversationMemberUpdate(conversation: conversation, member: member, status: .typingEnded)
    }

    func chatClient(_ client: TwilioChatClient, typingStartedOn conversation: TCHChannel, member: TCHMember) {
        self.memberUpdate = ConversationMemberUpdate(conversation: conversation, member: member, status: .typingStarted)
        self.handle(member: member, in: conversation, status: .typingStarted)
    }

    private func handle(member: TCHMember, in conversation: TCHChannel, status: ConversationMemberUpdate.Status) {
        
    }

    //MARK: MESSAGE UPDATES

    func chatClient(_ client: TwilioChatClient, conversation: TCHChannel, messageAdded message: TCHMessage) {
        self.messageUpdate = MessageUpdate(conversation: conversation, message: message, status: .added)

        if ConversationSupplier.shared.activeConversation.isNil,
           !message.isFromCurrentUser,
            message.context != .timeSensitive {

            ToastScheduler.shared.schedule(toastType: .newMessage(message, conversation))
        }
    }

    func chatClient(_ client: TwilioChatClient!, conversation: TCHChannel!, messageChanged message: TCHMessage!) {
        self.messageUpdate = MessageUpdate(conversation: conversation, message: message, status: .changed)
    }

    func chatClient(_ client: TwilioChatClient, conversation: TCHChannel, messageDeleted message: TCHMessage) {
        self.messageUpdate = MessageUpdate(conversation: conversation, message: message, status: .deleted)
    }

    func chatClient(_ client: TwilioChatClient!, toastReceivedOn conversation: TCHChannel!, message: TCHMessage!) {
        self.messageUpdate = MessageUpdate(conversation: conversation, message: message, status: .toastReceived)
    }
}

