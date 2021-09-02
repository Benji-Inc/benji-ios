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

        guard let channelDisplayable = ConversationSupplier.shared.activeConversation else {
            throw ClientError.message(detail: "No active channel found.")
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

        if case .channel(let channel) = channelDisplayable.channelType {
            do {
                try await self.sendMessage(to: channel,
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
        guard let channelDisplayable = ConversationSupplier.shared.activeConversation else {
            throw ClientError.message(detail: "No active channel found.")
        }

        guard case .channel(let channel) = channelDisplayable.channelType else {
            throw ClientError.message(detail: "No active channel found.")
        }

        let systemMessage = SystemMessage(with: message)
        systemMessageHandler?(systemMessage)
        
        let attributes = message.attributes ?? [:]
        try await self.sendMessage(to: channel,
                                   context: message.context,
                                   kind: message.kind,
                                   attributes: attributes)

        return systemMessage
    }

    //MARK: MESSAGE HELPERS

    @discardableResult
    private func sendMessage(to channel: TCHChannel,
                             context: MessageContext = .passive,
                             kind: MessageKind,
                             attributes: [String : Any] = [:]) async throws -> Messageable {

        if !ChatClientManager.shared.isConnected {
            throw ClientError.message(detail: "Chat service is disconnected.")
        }

        if channel.status != .joined {
            throw ClientError.message(detail: "You are not a channel member.")
        }

        let messagesObject = channel.messages!
        var mutableAttributes = attributes
        mutableAttributes["context"] = context.rawValue

        let options = try await self.getOptions(for: kind, attributes: mutableAttributes)

        let message: Messageable = try await withCheckedThrowingContinuation { continuation in
            messagesObject.sendMessage(with: options, completion: { (result, message) in
                if result.isSuccessful(), let msg = message {
                    self.donateIntent(for: msg, channel: channel)
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

    private func donateIntent(for message: Messageable, channel: TCHChannel) {
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
