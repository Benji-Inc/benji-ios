//
//  ConversationSupplier.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

protocol ActiveConversationAccessor: AnyObject {
    var activeConversation: DisplayableConversation? { get }
}

extension ActiveConversationAccessor {
    var activeConversation: DisplayableConversation? {
        return ConversationSupplier.shared.activeConversation
    }
}

class ConversationSupplier {

    static let shared = ConversationSupplier()

    private var allConversations: [DisplayableConversation] = [] {
        didSet {
            self.allConversationsSorted = self.allConversations.sorted()
        }
    }

    private(set) var allConversationsSorted: [DisplayableConversation] = []

    var allJoinedConversations: [DisplayableConversation] {
        return self.allConversationsSorted.filter({ (displayableConversation) -> Bool in
            switch displayableConversation.channelType {
            case .channel(let channel):
                return channel.status == .joined
            default:
                return false
            }
        })
    }

    var allInvitedConversations: [DisplayableConversation] {
        return self.allConversationsSorted.filter({ (displayableConversation) -> Bool in
            switch displayableConversation.channelType {
            case .channel(let channel):
                return channel.status == .invited
            default:
                return false
            }
        })
    }

    private var subscribedConversations: [DisplayableConversation] {
        get {
            guard let client = ChatClientManager.shared.client, let channels = client.channelsList() else { return [] }
            return channels.subscribedChannels().map { (channel) -> DisplayableConversation in
                return DisplayableConversation.init(channelType: .channel(channel))
            }
        }
    }

    private(set) var pendingConversationUniqueName: String?
    @Published private(set) var activeConversation: DisplayableConversation?
    @Published private(set) var isSynced: Bool = false
    @Published private(set) var channelsUpdate: ConversationUpdate?

    var cancellables = Set<AnyCancellable>()

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.isSynced = false
    }

    func set(activeConversation: DisplayableConversation?) {
        self.activeConversation = activeConversation

        self.pendingConversationUniqueName = nil

        if let displayable = activeConversation {
            switch displayable.channelType {
            case .pending(let uniqueName):
                self.pendingConversationUniqueName = uniqueName
            default:
                break
            }
        }
    }

    private func subscribeToUpdates() {
        ChatClientManager.shared.$clientSyncUpdate.mainSink { [weak self] (status) in
            guard let `self` = self, let clientStatus = status else { return }

            switch clientStatus {
            case .completed:
                self.allConversations = self.subscribedConversations
                self.isSynced = true
            default:
                break
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$channelsUpdate.mainSink { [weak self] (update) in
            guard let `self` = self, let channelsUpdate = update, self.isSynced else { return }
            switch channelsUpdate.status {
            case .added:
                self.allConversations = self.subscribedConversations
                if let uniqueName = self.pendingConversationUniqueName, channelsUpdate.channel.uniqueName == uniqueName {
                    self.set(activeConversation: DisplayableConversation(channelType: .channel(channelsUpdate.channel)))
                }
            case .deleted:
                // We pre-emptivley delete a channel from the client, so we dont have a delay, and a user doesn't select a deleted channel and cause a crash.
                self.allConversations = self.subscribedConversations.filter { (channel) -> Bool in
                    return channel.id != channelsUpdate.channel.id
                }

                if let activeConversation = self.activeConversation {
                    switch activeConversation.channelType {
                    case .channel(let channel):
                        if channelsUpdate.channel == channel {
                            self.activeConversation = nil
                        }
                    default:
                        break
                    }
                }
            default:
                break
            }
            // Forward the update once we have handled the update.
            self.channelsUpdate = update
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
            guard let `self` = self, let memberUpdate = update else { return }

            switch memberUpdate.status {
            case .left:
                // We pre-emptivley leave a channel from the client, so we dont have a delay, and a user doesn't still see a channel they left.
                self.allConversations = self.subscribedConversations.filter { (channel) -> Bool in
                    return channel.id != memberUpdate.channel.id
                }
                if let activeConversation = self.activeConversation {
                    switch activeConversation.channelType {
                    case .channel(let channel):
                        if memberUpdate.channel == channel {
                            self.activeConversation = nil
                        }
                    default:
                        break
                    }
                }
            case .joined, .changed:
                self.channelsUpdate = ConversationUpdate(channel: memberUpdate.channel, status: .changed)
            default:
                break
            }
        }.store(in: &self.cancellables)
    }

    func isConversationEqualToActiveConversation(channel: TCHChannel) -> Bool {
        guard let activeConversation = self.activeConversation else { return false }
        
        switch activeConversation.channelType {
        case .channel(let currentConversation):
            return currentConversation == channel
        default:
            return false
        }
    }

    // MARK: GETTERS

    func waitForInitialSync() async {
        var cancellable: AnyCancellable?

        return await withCheckedContinuation { continuation in
            cancellable = ConversationSupplier.shared.$isSynced
                .mainSink { (isSynced) in
                    guard isSynced else { return }

                    continuation.resume(returning: ())
                    cancellable?.cancel()
                }
        }
    }

    func getConversation(withSID channelSID: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (channel) in
            return channel.id == channelSID
        })
    }

    func getConversation(withUniqueName name: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (channel) in
            switch channel.channelType {
            case .channel(let tchConversation):
                return tchConversation.uniqueName == name
            default:
                return false
            }
        })
    }

    func getConversation(containingMember userID: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (channel) -> Bool in
            switch channel.channelType {
            case .channel(let tchConversation):
                return tchConversation.member(withIdentity: userID) != nil
            default:
                return false
            }
        })
    }

    func createConversation(uniqueName: String = UUID().uuidString,
                       friendlyName: String,
                       members: [String],
                       setActive: Bool = true) {
        
        if setActive {
            self.set(activeConversation: DisplayableConversation(channelType: .pending(uniqueName)))
        }

        Task {
            do {
                try await CreateConversation(uniqueName: uniqueName,
                                        friendlyName: friendlyName,
                                        attributes: [:],
                                        members: members)
                    .makeRequest(andUpdate: [], viewsToIgnore: [])
            } catch {
                print(error)
            }
        }
    }
}
