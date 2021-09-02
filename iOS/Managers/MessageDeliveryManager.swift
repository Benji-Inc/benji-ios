//
//  MessageDeliveryManager.swift
//  Benji
//
//  Created by Benji Dodgson on 5/25/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization
import Intents

class MessageDeliveryManager {

    static let shared = MessageDeliveryManager()

    func send(object: Sendable,
              attributes: [String: Any],
              systemMessageHandler: ((SystemMessage) -> Void)?) async throws -> SystemMessage {

        guard let conversationDisplayable = ConversationSupplier.shared.activeConversation else {
            throw ClientError.message(detail: "No active conversation found.")
        }

        guard let current = User.current(), let objectId = current.objectId else {
            throw ClientError.message(detail: "No id found for the current user.")
        }

        var mutableAttributes = attributes
        mutableAttributes["updateId"] = UUID().uuidString

        let systemMessage = SystemMessage(avatar: current,
                                          context: object.context,
                                          isFromCurrentUser: true,
                                          createdAt: Date(),
                                          authorId: objectId,
                                          messageIndex: nil,
                                          status: .sent,
                                          kind: object.kind,
                                          id: String(),
                                          attributes: mutableAttributes)
        systemMessageHandler?(systemMessage)

        if case .conversation(let conversation) = conversationDisplayable.conversationType {
            do {
                try await self.sendMessage(to: conversation,
                                           context: object.context,
                                           kind: object.kind,
                                           attributes: mutableAttributes)
            } catch {
                systemMessage.status = .error
            }
        }

        return systemMessage
    }

    func resend(message: Messageable, systemMessageHandler: ((SystemMessage) -> Void)?) async throws -> SystemMessage {
        guard let conversationDisplayable = ConversationSupplier.shared.activeConversation else {
            throw ClientError.message(detail: "No active conversation found.")
        }

        guard case .conversation(let conversation) = conversationDisplayable.conversationType else {
            throw ClientError.message(detail: "No active conversation found.")
        }

        let systemMessage = SystemMessage(with: message)
        systemMessageHandler?(systemMessage)
        
        let attributes = message.attributes ?? [:]
        try await self.sendMessage(to: conversation,
                                   context: message.context,
                                   kind: message.kind,
                                   attributes: attributes)

        return systemMessage
    }

    //MARK: MESSAGE HELPERS

    @discardableResult
    private func sendMessage(to conversation: TCHChannel,
                             context: MessageContext = .passive,
                             kind: MessageKind,
                             attributes: [String : Any] = [:]) async throws -> Messageable {

        if !ChatClientManager.shared.isConnected {
            throw ClientError.message(detail: "Chat service is disconnected.")
        }

        if conversation.status != .joined {
            throw ClientError.message(detail: "You are not a conversation member.")
        }

        let messagesObject = conversation.messages!
        var mutableAttributes = attributes
        mutableAttributes["context"] = context.rawValue

        let options = try await self.getOptions(for: kind, attributes: mutableAttributes)

        let message: Messageable = try await withCheckedThrowingContinuation { continuation in
            messagesObject.sendMessage(with: options, completion: { (result, message) in
                if result.isSuccessful(), let msg = message {
                    self.donateIntent(for: msg, conversation: conversation)
                    continuation.resume(returning: msg)
                } else if let e = result.error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(throwing: ClientError.message(detail: "Failed to send message."))
                }
            })
        }

        return message
    }

    private func donateIntent(for message: Messageable, conversation: TCHChannel) {
        let incomingMessageIntent: INSendMessageIntent = INSendMessageIntent(recipients: nil, outgoingMessageType: .outgoingMessageText, content: nil, speakableGroupName: nil, conversationIdentifier: nil, serviceName: nil, sender: nil, attachments: [])
        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .outgoing
        interaction.donate(completion: nil)
    }

    private func getOptions(for kind: MessageKind, attributes: [String : Any] = [:]) async throws -> TCHMessageOptions {
        let options = TCHMessageOptions()

        switch kind {
        case .text(let body):
            return await options.with(body: body, attributes: TCHJsonAttributes.init(dictionary: attributes))
        case .photo(let item, let body), .video(let item, let body):
            // Twilio can't send both media and text so we add it as an attribute
            var mutableAttributes = attributes
            mutableAttributes["body"] = body
            return await options.with(body: body,
                                      mediaItem: item,
                                      attributes: TCHJsonAttributes.init(dictionary: mutableAttributes))
        case .link(let url):
            var mutableAttributes = attributes
            mutableAttributes["isLink"] = true
            return await options.with(body: url.absoluteString,
                                      mediaItem: nil,
                                      attributes: TCHJsonAttributes.init(dictionary: mutableAttributes))
        default:
            throw ClientError.message(detail: "Unsupported MessageKind")
        }
    }
}
