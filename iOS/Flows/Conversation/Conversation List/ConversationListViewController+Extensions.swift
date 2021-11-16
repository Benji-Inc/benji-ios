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

        self.dataSource.handleSelectedMessage = { [unowned self] (message) in
            guard let cid = try? ConversationID(cid: message.conversationId) else { return }
            self.onSelectedConversation?(cid)
        }
        self.dataSource.handleLoadMoreMessages = { [unowned self] in
            self.loadMoreConversationsIfNeeded()
        }
    }

    func subscribeToKeyboardUpdates() {
        KeyboardManager.shared.addKeyboardObservers(with: self.inputAccessoryView)

        KeyboardManager.shared.$willKeyboardShow
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
                }
        }.store(in: &self.cancellables)

        self.collectionView.publisher(for: \.contentOffset).mainSink { [unowned self] _ in
            guard self.collectionView.isTracking else { return }
            self.collectionView.visibleCells.forEach { cell in
                if let messageCell = cell as? ConversationMessageCell {
                    messageCell.handle(isCentered: false)
                }
            }
        }.store(in: &self.cancellables)

        self.messageInputAccessoryView.textView.$inputText.mainSink { [unowned self] text in
            guard let currentConversation = self.currentConversation else { return }

            let conversationController = ChatClient.shared.channelController(for: currentConversation.cid)
            guard conversationController.areTypingEventsEnabled else { return }

            if !text.isEmpty {
                conversationController.sendKeystrokeEvent()
            } else {
                conversationController.sendStopTypingEvent()
            }
        }.store(in: &self.cancellables)

        self.$didCenterOnCell
            .mainSink { cell in
                guard let messageCell = cell else { return }
                messageCell.handle(isCentered: true)
                self.collectionView.visibleCells.forEach { cell in
                    if let offsetCell = cell as? ConversationMessageCell, offsetCell != messageCell {
                        offsetCell.handle(isCentered: false)
                    }
                }
            }.store(in: &self.cancellables)
    }
}
