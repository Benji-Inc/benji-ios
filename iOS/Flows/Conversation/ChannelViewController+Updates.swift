//
//  ConversationViewController+Updates.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension ConversationViewController {

    func loadMessages(for channelType: ConversationType) {
        self.collectionViewManager.reset()
        MessageSupplier.shared.reset()
        
        switch channelType {
        case .system(let channel):
            self.loadSystem(channel: channel)
        case .channel(_):
            Task {
                do {
                    let sections = try await MessageSupplier.shared.getLastMessages()
                    self.collectionViewManager.set(newSections: sections,
                                                   animate: true) {
                        self.setupDetailAnimator()
                    }
                } catch {
                    logDebug(error)
                }
            }
        case .pending(_):
            break 
        }
    }

    private func loadSystem(channel: SystemConversation) {
        let sections = MessageSupplier.shared.mapMessagesToSections(for: channel.messages, in: .system(channel))
        self.collectionViewManager.set(newSections: sections) { [weak self] in
            guard let `self` = self else { return }
            self.channelCollectionView.scrollToEnd()
        }
    }
    
    func subscribeToUpdates() {

        MessageSupplier.shared.$messageUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }

            guard let channelUpdate = update, ConversationSupplier.shared.isConversationEqualToActiveConversation(channel: channelUpdate.channel) else { return }

            switch channelUpdate.status {
            case .added:
                if self.channelCollectionView.isTypingIndicatorHidden {
                    self.collectionViewManager.updateItemSync(with: channelUpdate.message) {
                        self.channelCollectionView.scrollToEnd()
                    }
                } else {
                    self.collectionViewManager.setTypingIndicatorViewHidden(true, performUpdates: { [weak self] in
                        guard let `self` = self else { return }
                        self.collectionViewManager.updateItemSync(with: channelUpdate.message,
                                                              replaceTypingIndicator: true,
                                                              completion: nil)
                    })
                }
            case .changed:
                self.collectionViewManager.updateItemSync(with: channelUpdate.message)
            case .deleted:
                self.collectionViewManager.delete(item: channelUpdate.message)
            case .toastReceived:
                break
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
            guard let `self` = self else { return }
            guard let memberUpdate = update, ConversationSupplier.shared.isConversationEqualToActiveConversation(channel: memberUpdate.channel) else { return }

            switch memberUpdate.status {
            case .joined, .left:
                memberUpdate.channel.getMembersCount { [unowned self] (result, count) in
                    self.collectionViewManager.numberOfMembers = Int(count)
                }
            case .changed:
                break
            case .typingEnded:
                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
                    self.collectionViewManager.userTyping = nil
                    self.collectionViewManager.setTypingIndicatorViewHidden(true)
                }
            case .typingStarted:
                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
                    Task {
                        guard let user = try? await memberUpdate.member.getMemberAsUser() else { return }
                        self.collectionViewManager.userTyping = user
                        self.collectionViewManager.setTypingIndicatorViewHidden(false, performUpdates: nil)
                    }
                }
            }
        }.store(in: &self.cancellables)

        ChatClientManager.shared.$clientUpdate.mainSink { [weak self] (update) in
            guard let `self` = self, let update = update else { return }

            switch update.status {
            case .connectionState(let state):
                self.messageInputAccessoryView.handleConnection(state: state)
            default:
                break
            }
        }.store(in: &self.cancellables)
    }
}
