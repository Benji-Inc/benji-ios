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
import ReactiveSwift

protocol ActiveChannelAccessor: class {
    var activeChannel: DisplayableChannel? { get }
}

extension ActiveChannelAccessor {
    var activeChannel: DisplayableChannel? {
        return ChannelSupplier.shared.activeChannel.value
    }
}

class ChannelSupplier {

    static let shared = ChannelSupplier()

    let disposables = CompositeDisposable()

    private var allChannels: [DisplayableChannel] = [] {
        didSet {
            self.allChannelsSorted = self.allChannels.sorted()
        }
    }

    private(set) var allChannelsSorted: [DisplayableChannel] = []

    private(set) var activeChannel = MutableProperty<DisplayableChannel?>(nil)

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.disposables.dispose()
    }

    func set(activeChannel: DisplayableChannel?) {
        self.activeChannel.value = activeChannel
    }

    private func subscribeToUpdates() {

        self.disposables.add(ChannelManager.shared.clientSyncUpdate.producer.on { [weak self] (update) in
            guard let `self` = self else { return }

            guard let clientUpdate = update else { return }

            switch clientUpdate {
            case .started:
                break
            case .channelsListCompleted:
                break
            case .completed:
                self.allChannels = ChannelManager.shared.subscribedChannels.filter({ (displayableChannel) -> Bool in
                    switch displayableChannel.channelType {
                    case .channel(let channel):
                        return channel.status == .joined
                    default:
                        return false 
                    }
                })
            case .failed:
                break
            @unknown default:
                break
            }
        }.start())

        self.disposables.add(ChannelManager.shared.channelsUpdate.producer.on { [weak self] (update) in
            guard let `self` = self, let channelsUpdate = update else { return }

            switch channelsUpdate.status {
            case .added:
                self.allChannels = ChannelManager.shared.subscribedChannels
            case .deleted:
                // We pre-emptivley delete a channel from the client, so we dont have a delay, and a user doesn't select a deleted channel and cause a crash.
                self.allChannels = ChannelManager.shared.subscribedChannels.filter { (channel) -> Bool in
                    return channel.id != channelsUpdate.channel.id
                }

                if let activeChannel = self.activeChannel.value {
                    switch activeChannel.channelType {
                    case .channel(let channel):
                        if channelsUpdate.channel == channel {
                            self.activeChannel.value = nil
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }.start())

        self.disposables.add(ChannelManager.shared.memberUpdate.producer.on { [weak self] (update) in
            guard let `self` = self, let memberUpdate = update else { return }

            switch memberUpdate.status {
            case .left:
                // We pre-emptivley leave a channel from the client, so we dont have a delay, and a user doesn't still see a channel they left.
                self.allChannels = ChannelManager.shared.subscribedChannels.filter { (channel) -> Bool in
                    return channel.id != memberUpdate.channel.id
                }
                if let activeChannel = self.activeChannel.value {
                    switch activeChannel.channelType {
                    case .channel(let channel):
                        if memberUpdate.channel == channel {
                            self.activeChannel.value = nil
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }.start())
    }

    func isChannelEqualToActiveChannel(channel: TCHChannel) -> Bool {
        return false
    }

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
