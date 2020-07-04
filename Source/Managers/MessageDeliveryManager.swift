//
//  MessageDeliveryManager.swift
//  Benji
//
//  Created by Benji Dodgson on 5/25/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROFutures
import TMROLocalization

class MessageDeliveryManager {

    static func send(message: String,
                     context: MessageContext = .casual,
                     kind: MessageKind,
                     attributes: [String: Any],
                     completion: @escaping (SystemMessage?, Error?) -> Void) -> SystemMessage? {

        if let channelDisplayable = ChannelSupplier.shared.activeChannel.value {
            if let current = User.current(), let objectId = current.objectId {

                var mutableAttributes = attributes
                mutableAttributes["updateId"] = UUID().uuidString

                let systemMessage = SystemMessage(avatar: current,
                                                  context: context,
                                                  isFromCurrentUser: true,
                                                  createdAt: Date(),
                                                  authorId: objectId,
                                                  messageIndex: nil,
                                                  status: .sent,
                                                  kind: kind,
                                                  id: String(),
                                                  attributes: mutableAttributes)

                if case .channel(let channel) = channelDisplayable.channelType {
                    self.sendMessage(to: channel, with: message, context: context, attributes: mutableAttributes)
                        .observe { (result) in
                            switch result {
                            case .success(_):
                                completion(systemMessage, nil)
                            case .failure(let error):
                                completion(systemMessage, error)
                            }
                    }
                } else {

                }

                return systemMessage

            } else {
                completion(nil, ClientError.message(detail: "No id found for the current user."))
            }
        } else {
            completion(nil, ClientError.message(detail: "No active channel found."))
        }

        return nil
    }

    static func resend(message: Messageable, completion: @escaping (SystemMessage?, Error?) -> Void) -> SystemMessage? {

        if let channelDisplayable = ChannelSupplier.shared.activeChannel.value {
            let systemMessage = SystemMessage(with: message)

            if case .channel(let channel) = channelDisplayable.channelType {
                let attributes = message.attributes ?? [:]
                switch message.kind {
                case .text(let text):
                    self.sendMessage(to: channel, with: text, context: message.context, attributes: attributes)
                        .observe { (result) in
                            switch result {
                            case .success(_):
                                completion(systemMessage, nil)
                            case .failure(let error):
                                completion(systemMessage, error)
                            }
                    }
                default:
                    break
                }
            } else {
                completion(nil, ClientError.message(detail: "No active channel found."))
            }

            return systemMessage
        } else {
            completion(nil, ClientError.message(detail: "No active channel found."))
        }

        return nil 
    }

    //MARK: MESSAGE HELPERS

    private static func sendMessage(to channel: TCHChannel,
                                    with body: String,
                                    context: MessageContext = .casual,
                                    attributes: [String : Any] = [:]) -> Future<Messageable> {

        let message = body.extraWhitespaceRemoved()
        let promise = Promise<Messageable>()
        var mutableAttributes = attributes
        mutableAttributes["context"] = context.rawValue

        if !ChannelManager.shared.isConnected {
            promise.reject(with: ClientError.message(detail: "Chat service is disconnected."))
        }

        if message.isEmpty {
            promise.reject(with: ClientError.message(detail: "Your message can not be empty."))
        }

        if channel.status != .joined {
            promise.reject(with: ClientError.message(detail: "You are not a channel member."))
        }

        if let tchAttributes = TCHJsonAttributes.init(dictionary: mutableAttributes) {
            if let messages = channel.messages {
                let messageOptions = TCHMessageOptions().withBody(body)
                messageOptions.withAttributes(tchAttributes, completion: nil)
                messages.sendMessage(with: messageOptions) { (result, message) in
                    if result.isSuccessful(), let msg = message {
                        promise.resolve(with: msg)
                    } else if let error = result.error {
                        promise.reject(with: error)
                    } else {
                        promise.reject(with: ClientError.message(detail: "Failed to send message."))
                    }
                }
            } else {
                promise.reject(with: ClientError.message(detail: "No messages object found on channel."))
            }
        } else {
            promise.reject(with: ClientError.message(detail: "Message attributes failed to initialize."))
        }


        return promise.withResultToast()
    }
}
