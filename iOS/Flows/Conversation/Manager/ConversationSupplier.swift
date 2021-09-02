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
            switch displayableConversation.conversationType {
            case .conversation(let conversation):
                return conversation.status == .joined
            default:
                return false
            }
        })
    }

    var allInvitedConversations: [DisplayableConversation] {
        return self.allConversationsSorted.filter({ (displayableConversation) -> Bool in
            switch displayableConversation.conversationType {
            case .conversation(let conversation):
                return conversation.status == .invited
            default:
                return false
            }
        })
    }

    private var subscribedConversations: [DisplayableConversation] {
        get {
            guard let client = ChatClientManager.shared.client, let conversations = client.conversationsList() else { return [] }
            return conversations.subscribedChannels().map { (conversation) -> DisplayableConversation in
                return DisplayableConversation.init(conversationType: .conversation(conversation))
            }
        }
    }

    private(set) var pendingConversationUniqueName: String?
    @Published private(set) var activeConversation: DisplayableConversation?
    @Published private(set) var isSynced: Bool = false
    @Published private(set) var conversationsUpdate: ConversationUpdate?

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
            switch displayable.conversationType {
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

        ChatClientManager.shared.$conversationsUpdate.mainSink { [weak self] (update) in
            guard let `self` = self, let conversationsUpdate = update, self.isSynced else { return }
            switch conversationsUpdate.status {
            case .added:
                self.allConversations = self.subscribedConversations
                if let uniqueName = self.pendingConversationUniqueName, conversationsUpdate.conversation.uniqueName == uniqueName {
                    self.set(activeConversation: DisplayableConversation(conversationType: .conversation(conversationsUpdate.conversation)))
                }
            case .deleted:
                // We pre-emptivley delete a conversation from the client, so we dont have a delay, and a user doesn't select a deleted conversation and cause a crash.
                self.allConversations = self.subscribedConversations.filter { (conversation) -> Bool in
                    return conversation.id != conversationsUpdate.conversation.id
                }

                if let activeConversation = self.activeConversation {
                    switch activeConversation.conversationType {
                    case .conversation(let conversation):
                        if conversationsUpdate.conversation == conversation {
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
            self.conversationsUpdate = update
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
            guard let `self` = self, let memberUpdate = update else { return }

            switch memberUpdate.status {
            case .left:
                // We pre-emptivley leave a conversation from the client, so we dont have a delay, and a user doesn't still see a conversation they left.
                self.allConversations = self.subscribedConversations.filter { (conversation) -> Bool in
                    return conversation.id != memberUpdate.conversation.id
                }
                if let activeConversation = self.activeConversation {
                    switch activeConversation.conversationType {
                    case .conversation(let conversation):
                        if memberUpdate.conversation == conversation {
                            self.activeConversation = nil
                        }
                    default:
                        break
                    }
                }
            case .joined, .changed:
                self.conversationsUpdate = ConversationUpdate(conversation: memberUpdate.conversation, status: .changed)
            default:
                break
            }
        }.store(in: &self.cancellables)
    }

    func isConversationEqualToActiveConversation(conversation: TCHChannel) -> Bool {
        guard let activeConversation = self.activeConversation else { return false }
        
        switch activeConversation.conversationType {
        case .conversation(let currentConversation):
            return currentConversation == conversation
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

    func getConversation(withSID conversationSID: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (conversation) in
            return conversation.id == conversationSID
        })
    }

    func getConversation(withUniqueName name: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (conversation) in
            switch conversation.conversationType {
            case .conversation(let tchConversation):
                return tchConversation.uniqueName == name
            default:
                return false
            }
        })
    }

    func getConversation(containingMember userID: String) -> DisplayableConversation? {
        return self.subscribedConversations.first(where: { (conversation) -> Bool in
            switch conversation.conversationType {
            case .conversation(let tchConversation):
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
            self.set(activeConversation: DisplayableConversation(conversationType: .pending(uniqueName)))
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
