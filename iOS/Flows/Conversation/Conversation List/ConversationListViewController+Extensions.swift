//
//  ConversationListViewController+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationListViewController {

    func setupInputHandlers() {
        self.dataSource.handleSelectedMessage = { [unowned self] (cid, messageID, view) in
            self.selectedMessageView = view
            self.onSelectedMessage?(cid, messageID, nil)
        }

        self.dataSource.handleEditMessage = { cid, messagerID in
            // TODO
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] in
            self.loadMoreConversationsIfNeeded()
        }
        
        self.dataSource.handleCollectionViewTapped = {
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            } else {
                self.messageInputAccessoryView.textView.becomeFirstResponder()
            }
        }
    }

    func subscribeToUIUpdates() {
        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.updateUI(for: state)
            }.store(in: &self.cancellables)
        
        KeyboardManager.shared
            .$currentEvent
            .mainSink { [weak self] currentEvent in
                guard let `self` = self else { return }

                switch currentEvent {
                case .willShow:
                    self.state = .write
                case .willHide:
                    self.state = .read
                case .didChangeFrame:
                    self.view.setNeedsLayout()
                default:
                    break
                }
            }.store(in: &self.cancellables)
    }

    func subscribeToConversationUpdates() {
        self.conversationListController
            .channelsChangesPublisher
            .mainSink { [unowned self] _ in
                Task {
                    await self.dataSource.update(with: self.conversationListController)
                }.add(to: self.autocancelTaskPool)
            }.store(in: &self.cancellables)

        self.messageInputAccessoryView.textView.$inputText.mainSink { [unowned self] text in
            guard let conversationController = self.getCurrentConversationController() else { return }

            guard conversationController.areTypingEventsEnabled else { return }

            if text.isEmpty {
                conversationController.sendStopTypingEvent()
            } else {
                conversationController.sendKeystrokeEvent()
            }
        }.store(in: &self.cancellables)
        
        ConversationsManager.shared.$activeConversation.mainSink { [weak self] conversation in
            guard let `self` = self else { return }

            if let convo = conversation,
               let cell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell {
                self.subscribeToTopMessageUpdates(for: convo, cell: cell)
            }
        }.store(in: &self.cancellables)
    }
    
    func subscribeToTopMessageUpdates(for conversation: Conversation, cell: ConversationMessagesCell) {
        // didUpdate is called before this is ever set.
        // Also looks like a non centered conversation is being used
        self.frontmostNonUserMessageSubscription = cell.$frontmostNonUserMessage
            .removeDuplicates()
            .mainSink { [unowned self] message in
                guard let author = message?.author else { return }

                self.headerVC.membersVC.scroll(to: author)
            }
    }
}
