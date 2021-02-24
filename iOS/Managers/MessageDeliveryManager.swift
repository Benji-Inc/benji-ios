//
//  MessageDeliveryManager.swift
//  Benji
//
//  Created by Benji Dodgson on 5/25/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine
import TMROLocalization

class MessageDeliveryManager {

    static let shared = MessageDeliveryManager()
    private var cancellables = Set<AnyCancellable>()

    func send(object: Sendable,
              attributes: [String: Any],
              completion: @escaping (SystemMessage?, Error?) -> Void) -> SystemMessage? {

        if let channelDisplayable = ChannelSupplier.shared.activeChannel {
            if let current = User.current(), let objectId = current.objectId {

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

                if case .channel(let channel) = channelDisplayable.channelType {
                    self.sendMessage(to: channel,
                                     context: object.context,
                                     kind: object.kind,
                                     attributes: mutableAttributes)
                        .mainSink(receivedResult: { (result) in
                            switch result {
                            case .success(_):
                                completion(systemMessage, nil)
                            case .error(let e):
                                completion(systemMessage, e)
                            }
                        }).store(in: &self.cancellables)
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

    func resend(message: Messageable, completion: @escaping (SystemMessage?, Error?) -> Void) -> SystemMessage? {

        if let channelDisplayable = ChannelSupplier.shared.activeChannel {
            let systemMessage = SystemMessage(with: message)

            if case .channel(let channel) = channelDisplayable.channelType {
                let attributes = message.attributes ?? [:]
                self.sendMessage(to: channel,
                                 context: message.context,
                                 kind: message.kind,
                                 attributes: attributes)
                    .mainSink(receivedResult: { (result) in
                        switch result {
                        case .success(_):
                            completion(systemMessage, nil)
                        case .error(let e):
                            completion(systemMessage, e)
                        }
                    }).store(in: &self.cancellables)
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

    private func sendMessage(to channel: TCHChannel,
                             context: MessageContext = .casual,
                             kind: MessageKind,
                             attributes: [String : Any] = [:]) -> AnyPublisher<Messageable, Error> {

        return Future { promise in

            if !ChatClientManager.shared.isConnected {
                promise(.failure(ClientError.message(detail: "Chat service is disconnected.")))
            }

            if channel.status != .joined {
                promise(.failure(ClientError.message(detail: "You are not a channel member.")))
            }

            let messagesObject = channel.messages!
            var mutableAttributes = attributes
            mutableAttributes["context"] = context.rawValue

            self.getOptions(for: kind, attributes: mutableAttributes)
                .mainSink { result in
                    switch result {
                    case .success(let options):
                        messagesObject.sendMessage(with: options, completion: { (result, message) in
                            if result.isSuccessful(), let msg = message {
                                promise(.success(msg))
                            } else if let e = result.error {
                                promise(.failure(e))
                            } else {
                                promise(.failure(ClientError.message(detail: "Failed to send message.")))
                            }
                        })
                    case .error(let e):
                        promise(.failure(e))
                    }
                }.store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }

    private func getOptions(for kind: MessageKind, attributes: [String : Any] = [:]) -> Future<TCHMessageOptions, Error> {
        let options = TCHMessageOptions()

        switch kind {
        case .text(let body):
            return options.with(body: body, attributes: TCHJsonAttributes.init(dictionary: attributes))
        case .photo(let item, let body), .video(let item, let body):
            // Twilio can't send both media and text so we add it as an attribute
            var mutableAttributes = attributes
            mutableAttributes["body"] = body
            return options.with(body: body, mediaItem: item, attributes: TCHJsonAttributes.init(dictionary: mutableAttributes))
        default:
            return Future { promise in
                promise(.failure(ClientError.message(detail: "Unsupported MessageKind")))
            }
        }
    }
}
