//
//  ChannelSupplier.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine
import ReactiveSwift

protocol ActiveChannelAccessor: class {
    var activeChannel: DisplayableChannel? { get }
}

extension ActiveChannelAccessor {
    var activeChannel: DisplayableChannel? {
        return ChannelSupplier.shared.activeChannel
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

    var allJoinedChannels: [DisplayableChannel] {
        return self.allChannelsSorted.filter({ (displayableChannel) -> Bool in
            switch displayableChannel.channelType {
            case .channel(let channel):
                return channel.status == .joined
            default:
                return false
            }
        })
    }

    var allInvitedChannels: [DisplayableChannel] {
        return self.allChannelsSorted.filter({ (displayableChannel) -> Bool in
            switch displayableChannel.channelType {
            case .channel(let channel):
                return channel.status == .invited
            default:
                return false
            }
        })
    }

    private var subscribedChannels: [DisplayableChannel] {
        get {
            guard let client = ChannelManager.shared.client, let channels = client.channelsList() else { return [] }
            return channels.subscribedChannels().map { (channel) -> DisplayableChannel in
                return DisplayableChannel.init(channelType: .channel(channel))
            }
        }
    }

    private(set) var pendingChannelUniqueName: String?
    @Published private(set) var activeChannel: DisplayableChannel?
    @Published private(set) var isSynced: Bool = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.isSynced = false 
        self.disposables.dispose()
    }

    func set(activeChannel: DisplayableChannel?) {

        self.activeChannel = activeChannel

        self.pendingChannelUniqueName = nil

        if let displayable = activeChannel {
            switch displayable.channelType {
            case .pending(let uniqueName):
                self.pendingChannelUniqueName = uniqueName
            default:
                break
            }
        }
    }

    func createChannel(uniqueName: String = UUID().uuidString,
                       friendlyName: String,
                       context: ConversationContext,
                       members: [String],
                       setActive: Bool = true) {

        var attributes: [String: Any] = [:]
        attributes[ChannelKey.context.rawValue] = context.rawValue
        CreateChannel(uniqueName: uniqueName, friendlyName: friendlyName, attributes: attributes, members: members)
            .makeRequest(andUpdate: [], viewsToIgnore: [])
            .observeValue { (_) in
                if setActive {
                    self.set(activeChannel: DisplayableChannel(channelType: .pending(uniqueName)))
                }
        }
    }

    private func subscribeToUpdates() {
        ChannelManager.shared.$clientSyncUpdate.mainSink { [weak self] (status) in
            guard let `self` = self, let clientStatus = status else { return }

            switch clientStatus {
            case .completed:
                self.allChannels = self.subscribedChannels
                self.isSynced = true
            default:
                break
            }
        }.store(in: &self.cancellables)

        self.disposables.add(ChannelManager.shared.channelsUpdate.producer.on(value:  { [weak self] (update) in
            guard let `self` = self, let channelsUpdate = update else { return }
            
            switch channelsUpdate.status {
            case .added:
                self.allChannels = self.subscribedChannels
                if let uniqueName = self.pendingChannelUniqueName, channelsUpdate.channel.uniqueName == uniqueName {
                    self.set(activeChannel: DisplayableChannel(channelType: .channel(channelsUpdate.channel)))
                }
            case .deleted:
                // We pre-emptivley delete a channel from the client, so we dont have a delay, and a user doesn't select a deleted channel and cause a crash.
                self.allChannels = self.subscribedChannels.filter { (channel) -> Bool in
                    return channel.id != channelsUpdate.channel.id
                }
                
                if let activeChannel = self.activeChannel {
                    switch activeChannel.channelType {
                    case .channel(let channel):
                        if channelsUpdate.channel == channel {
                            self.activeChannel = nil
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }).start())

        self.disposables.add(ChannelManager.shared.memberUpdate.producer.on(value:  { [weak self] (update) in
            guard let `self` = self, let memberUpdate = update else { return }
            
            switch memberUpdate.status {
            case .left:
                // We pre-emptivley leave a channel from the client, so we dont have a delay, and a user doesn't still see a channel they left.
                self.allChannels = self.subscribedChannels.filter { (channel) -> Bool in
                    return channel.id != memberUpdate.channel.id
                }
                if let activeChannel = self.activeChannel {
                    switch activeChannel.channelType {
                    case .channel(let channel):
                        if memberUpdate.channel == channel {
                            self.activeChannel = nil
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
        }).start())
    }

    func isChannelEqualToActiveChannel(channel: TCHChannel) -> Bool {
        guard let activeChannel = self.activeChannel else { return false }
        
        switch activeChannel.channelType {
        case .channel(let currentChannel):
            return currentChannel == channel
        default:
            return false
        }
    }

    // MARK: GETTERS

    func getChannel(withSID channelSID: String) -> DisplayableChannel? {
        return self.subscribedChannels.first(where: { (channel) in
            return channel.id == channelSID
        })
    }

    func getChannel(withUniqueName name: String) -> DisplayableChannel? {
        return self.subscribedChannels.first(where: { (channel) in
            switch channel.channelType {
            case .channel(let tchChannel):
                return tchChannel.uniqueName == name
            default:
                return false 
            }
        })
    }

    func getChannel(containingMember userID: String) -> DisplayableChannel? {
        return self.subscribedChannels.first(where: { (channel) -> Bool in
            switch channel.channelType {
            case .channel(let tchChannel):
                return tchChannel.member(withIdentity: userID) != nil
            default:
                return false
            }
        })
    }
}
