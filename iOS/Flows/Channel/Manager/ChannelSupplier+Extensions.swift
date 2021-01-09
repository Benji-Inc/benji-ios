//
//  ChannelSupplier+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import TwilioChatClient

extension ChannelSupplier {

    func find(channelId: String) -> Future<TCHChannel, Error> {
        return Future { promise in
            guard let channels = ChatClientManager.shared.client?.channelsList() else {
                return promise(.failure(ClientError.message(detail: "No channels were found.")))
            }

            channels.channel(withSidOrUniqueName: channelId) { (result, channel) in
                if let strongChannel = channel, result.isSuccessful() {
                    promise(.success(strongChannel))
                } else if let error = result.error {
                    promise(.failure(error))
                } else {
                    promise(.failure(ClientError.message(detail: "No channel with that ID was found.")))
                }
            }
        }
    }

    @discardableResult
    static func leave(channel: TCHChannel) -> Future<Void, Error> {
        return Future { promise in
            channel.leave { result in
                if result.isSuccessful() {
                    promise(.success(()))
                } else if let error = result.error {
                    promise(.failure(error))
                } else {
                    promise(.failure(ClientError.message(detail: "Failed to leave channel.")))
                }
            }
        }
    }

    @discardableResult
    static func delete(channel: TCHChannel) -> Future<Void, Error> {
        return Future { promise in
            channel.destroy { result in
                if result.isSuccessful() {
                    promise(.success(()))
                } else if let error = result.error {
                    promise(.failure(error))
                } else {
                    promise(.failure(ClientError.message(detail: "Failed to delete channel.")))
                }
            }
        }
    }
}
