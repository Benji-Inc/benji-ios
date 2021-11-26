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
        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.dataSource.handleSelectedMessage = { [unowned self] (item, view) in
            self.selectedMessageView = view 
            self.onSelectedMessage?(item.channelID, item.messageID)
        }

        self.dataSource.handleDeletedConversation = { (conversation) in
            Task {
                do {
                    let cid = try ConversationID(cid: conversation.conversationId)
                    let conversationController = ChatClient.shared.channelController(for: cid)
                    if conversationController.conversation.isFromCurrentUser {
                        try await conversationController.deleteChannel()
                    } else {
                        try await conversationController.hideChannel()
                    }
                } catch {
                    logDebug(error)
                }
            }
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] in
            self.loadMoreConversationsIfNeeded()
        }
    }

    func subscribeToKeyboardUpdates() {
        KeyboardManager.shared.$willKeyboardShow
            .filter({ willShow in
                if let view = KeyboardManager.shared.inputAccessoryView as? SwipeableInputAccessoryView {
                    return view.textView.restorationIdentifier == self.messageInputAccessoryView.textView.restorationIdentifier
                }
                return false 
            })
            .mainSink { [unowned self] willShow in
                self.state = willShow ? .write : .read
            }.store(in: &self.cancellables)
    }

    func subscribeToUpdates() {

        self.$state
            .removeDuplicates()
            .mainSink { [unowned self] state in
                self.updateUI(for: state)
            }.store(in: &self.cancellables)

        self.conversationListController
            .channelsChangesPublisher
            .mainSink { [unowned self] changes in
                Task {
                    await self.dataSource.update(with: changes,
                                                 conversationController: self.conversationListController,
                                                 collectionView: self.collectionView)
                }.add(to: self.taskPool)
        }.store(in: &self.cancellables)

        self.collectionView.publisher(for: \.contentOffset).mainSink { [unowned self] _ in
            guard self.collectionView.isTracking else { return }
            self.collectionView.visibleCells.forEach { cell in
                if let messageCell = cell as? ConversationMessagesCell {
                    messageCell.handle(isCentered: false)
                }
            }
        }.store(in: &self.cancellables)

        self.messageInputAccessoryView.textView.$inputText.mainSink { [unowned self] text in
            guard let conversationController = self.conversationController else { return }

            guard conversationController.areTypingEventsEnabled else { return }

            if text.isEmpty {
                conversationController.sendStopTypingEvent()
            } else {
                conversationController.sendKeystrokeEvent()
            }
        }.store(in: &self.cancellables)

        self.$didCenterOnCell
            .mainSink { cell in
                guard let messageCell = cell else { return }
                messageCell.handle(isCentered: true)
                self.collectionView.visibleCells.forEach { cell in
                    if let offsetCell = cell as? ConversationMessagesCell, offsetCell != messageCell {
                        offsetCell.handle(isCentered: false)
                    }
                }
            }.store(in: &self.cancellables)
    }
}
