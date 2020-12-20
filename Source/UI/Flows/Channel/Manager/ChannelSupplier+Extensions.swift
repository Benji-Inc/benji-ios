//
//  ChannelSupplier+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROFutures
import TwilioChatClient

extension ChannelSupplier {

    func find(channelId: String) -> Future<TCHChannel> {
        let promise = Promise<TCHChannel>()

        guard let channels = ChannelManager.shared.client?.channelsList() else {
            promise.reject(with: ClientError.message(detail: "No channels were found."))
            return promise
        }

        channels.channel(withSidOrUniqueName: channelId) { (result, channel) in
            if let strongChannel = channel, result.isSuccessful() {
                promise.resolve(with: strongChannel)
            } else if let error = result.error {
                promise.reject(with: error)
            } else {
                promise.reject(with: ClientError.message(detail: "No channel with that ID was found."))
            }
        }

        return promise
    }

    /// Channels can only be found by user if they have already joined or are invited
    func findChannel(with channelId: String) -> Future<TCHChannel> {

        let promise = Promise<TCHChannel>()
        self.find(channelId: channelId)
            .observe(with: { (result) in
                switch result {
                case .success(let channel):
                    promise.resolve(with: channel)
                case .failure(let error):
                    promise.reject(with: error)
                }
            })

        return promise
    }

    @discardableResult
    static func leave(channel: TCHChannel) -> Future<Void> {
        let promise = Promise<Void>()

        channel.leave { result in
            if result.isSuccessful() {
                promise.resolve(with: ())
            } else if let error = result.error {
                promise.reject(with: error)
            } else {
                promise.reject(with: ClientError.message(detail: "Failed to leave channel."))
            }
        }

        return promise
    }

    @discardableResult
    static func delete(channel: TCHChannel) -> Future<Void>{
        let promise = Promise<Void>()

        channel.destroy { result in
            if result.isSuccessful() {
                promise.resolve(with: ())
            } else if let error = result.error {
                promise.reject(with: error)
            } else {
                promise.reject(with: ClientError.message(detail: "Failed to delete channel."))
            }
        }

        return promise
    }
}
