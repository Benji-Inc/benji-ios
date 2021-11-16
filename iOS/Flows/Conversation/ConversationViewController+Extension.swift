//
//  ConversationViewController+Updates.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension ConversationViewController {

    func setupInputHandlers() {
        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.dataSource.handleSelectedMessage = { [unowned self] (message) in
            self.onSelectedThread?(self.conversation.cid, message.id)
        }
        self.dataSource.handleLoadMoreMessages = { [unowned self] in
            self.loadMoreMessageIfNeeded()
        }
        self.dataSource.handleDeleteMessage = { [unowned self] message in
            self.conversationController?.deleteMessage(message.id)
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
        
        self.conversationController?.messagesChangesPublisher.mainSink { [unowned self] changes in
            Task {
                guard let conversationController = self.conversationController else { return }
                await self.dataSource.update(with: changes,
                                             conversationController: conversationController,
                                             collectionView: self.collectionView)
            }
        }.store(in: &self.cancellables)

        self.conversationController?.channelChangePublisher.mainSink { [unowned self] change in
            switch change {
            case .update(let conversation):
                self.conversationHeader.configure(with: conversation)
            case .create, .remove:
                break
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

        self.messageInputAccessoryView.textView.$inputText.mainSink { [unowned self] _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
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
