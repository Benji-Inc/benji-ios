//
//  ConversationViewController+Updates.swift
//  Benji
//
//  Created by Benji Dodgson on 11/11/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationViewController {
    
    func loadMessages(for conversationType: ConversationType) {
        self.collectionViewManager.reset()
        
        switch conversationType {
        case .system(let conversation):
            self.loadSystem(conversation: conversation)
        case .conversation(let channel):
            Task {
                do {
                    let controller = ChatClient.shared.channelController(for: channel.cid)
                    try await controller.loadPreviousMessages()
                    let messages = controller.messages.filter { _ in
                        return true
                    }
                    let section = ConversationSectionable(date: channel.updatedAt,
                                                          items: messages,
                                                          conversationType: .conversation(channel))
                    
                    self.collectionViewManager.set(newSections: [section],
                                                   animate: true) {
                        self.setupDetailAnimator()
                    }
                } catch {
                    logDebug(error)
                }
            }
        }
    }

    private func loadSystem(conversation: SystemConversation) {
        #warning("Replace")
//        let sections = MessageSupplier.shared.mapMessagesToSections(for: conversation.messages, in: .system(conversation))
//        self.collectionViewManager.set(newSections: sections) { [weak self] in
//            guard let `self` = self else { return }
//            self.conversationCollectionView.scrollToEnd()
//        }
    }
    
    func subscribeToUpdates() {

        #warning("Replace")
//        MessageSupplier.shared.$messageUpdate.mainSink { [weak self] (update) in
//            guard let `self` = self else { return }
//
//            guard let conversationUpdate = update, ConversationSupplier.shared.isConversationEqualToActiveConversation(conversation: conversationUpdate.conversation) else { return }
//
//            switch conversationUpdate.status {
//            case .added:
//                if self.conversationCollectionView.isTypingIndicatorHidden {
//                    self.collectionViewManager.updateItemSync(with: conversationUpdate.message) {
//                        self.conversationCollectionView.scrollToEnd()
//                    }
//                } else {
//                    self.collectionViewManager.setTypingIndicatorViewHidden(true, performUpdates: { [weak self] in
//                        guard let `self` = self else { return }
//                        self.collectionViewManager.updateItemSync(with: conversationUpdate.message,
//                                                              replaceTypingIndicator: true,
//                                                              completion: nil)
//                    })
//                }
//            case .changed:
//                self.collectionViewManager.updateItemSync(with: conversationUpdate.message)
//            case .deleted:
//                self.collectionViewManager.delete(item: conversationUpdate.message)
//            case .toastReceived:
//                break
//            }
//        }.store(in: &self.cancellables)

//        ChatClientManager.shared.$memberUpdate.mainSink { [weak self] (update) in
//            guard let `self` = self else { return }
//            guard let memberUpdate = update, ConversationSupplier.shared.isConversationEqualToActiveConversation(conversation: memberUpdate.conversation) else { return }
//
//            switch memberUpdate.status {
//            case .joined, .left:
//                memberUpdate.conversation.getMembersCount { [unowned self] (result, count) in
//                    self.collectionViewManager.numberOfMembers = Int(count)
//                }
//            case .changed:
//                break
//            case .typingEnded:
//                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
//                    self.collectionViewManager.userTyping = nil
//                    self.collectionViewManager.setTypingIndicatorViewHidden(true)
//                }
//            case .typingStarted:
//                if let memberID = memberUpdate.member.identity, memberID != User.current()?.objectId {
//                    Task {
//                        guard let user = try? await memberUpdate.member.getMemberAsUser() else { return }
//                        self.collectionViewManager.userTyping = user
//                        self.collectionViewManager.setTypingIndicatorViewHidden(false, performUpdates: nil)
//                    }
//                }
//            }
//        }.store(in: &self.cancellables)

        #warning("replace")
//        ChatClientManager.shared.$clientUpdate.mainSink { [weak self] (update) in
//            guard let `self` = self, let update = update else { return }
//
//            switch update.status {
//            case .connectionState(let state):
//                self.messageInputAccessoryView.handleConnection(state: state)
//            default:
//                break
//            }
//        }.store(in: &self.cancellables)
    }
}
