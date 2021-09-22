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
    
    func loadMessages(for conversation: Conversation) {
        self.collectionViewManager.reset()

        Task {
            do {
                let controller = ChatClient.shared.channelController(for: conversation.cid)
                try await controller.loadPreviousMessages()
                let messages: [Messageable] = controller.messages.reversed()
                let section = ConversationSectionable(date: conversation.updatedAt,
                                                      items: messages,
                                                      conversation: conversation)

                self.collectionViewManager.set(newSections: [section],
                                               animate: true) {
                    self.setupDetailAnimator()
                }
            } catch {
                logDebug(error)
            }
        }
    }

    func subscribeToUpdates() {
        guard let conversation = self.conversation else { return }

        let controller = ChatClient.shared.channelController(for: conversation.cid)
        controller.messagesChangesPublisher.mainSink { [weak self] (changes: [ListChange<ChatMessage>]) in
            guard let `self` = self else { return }

            for change in changes {
                switch change {
                case .insert(let message, _):
                    self.collectionViewManager.append(item: message, completion: nil)
                case .move(_, _, _):
                    return
                case .update(_, _):
                    return
                case .remove(_, _):
                    return
                }
            }
        }.store(in: &self.cancellables)
    }

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
}
