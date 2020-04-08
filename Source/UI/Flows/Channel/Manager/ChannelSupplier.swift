//
//  ChannelSupplier.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROFutures
import TMROLocalization

class ChannelSupplier {

    // MARK: CREATION

    static func createChannel(channelName: String,
                              context: ConversationContext,
                              type: TCHChannelType,
                              attributes: NSMutableDictionary = [:]) -> Future<TCHChannel> {

        guard let client = ChannelManager.shared.client else {
            let errorMessage = "Unable to create channel. Twilio client uninitialized"
            return Promise<TCHChannel>(error: ClientError.apiError(detail: errorMessage))
        }

        attributes[ChannelKey.context.rawValue] = context.rawValue

        return client.createChannel(channelName: channelName,
                                    uniqueName: UUID().uuidString,
                                    type: type,
                                    attributes: attributes)
    }

    @discardableResult
    static func delete(channel: TCHChannel) -> Future<Void> {
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

    // MARK: GETTERS

    static func getChannel(withSID channelSID: String) -> DisplayableChannel? {
        return ChannelManager.shared.subscribedChannels.first(where: { (channel) in
            return channel.id == channelSID
        })
    }

    /// Channels can only be found by user if they have already joined or are invited
    static func findChannel(with channelId: String) -> Future<TCHChannel> {

        let promise = Promise<TCHChannel>()
        ChannelManager.shared.client?.findChannel(with: channelId)
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

    static func getChannel(containingMember userID: String) -> DisplayableChannel? {
        return ChannelManager.shared.subscribedChannels.first(where: { (channel) -> Bool in
            switch channel.channelType {
            case .channel(let tchChannel):
                return tchChannel.member(withIdentity: userID) != nil
            default:
                return false
            }
        })
    }
}
