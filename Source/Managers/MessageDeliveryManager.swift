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

class MessageDeliveryManager {

    //MARK: MESSAGE HELPERS

    @discardableResult
    static func sendMessage(to channel: TCHChannel,
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
