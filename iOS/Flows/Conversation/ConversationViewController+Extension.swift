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

    func setupCompletionHandlers() {

        self.conversationHeader.button.didSelect { [unowned self] in
            self.didTapMoreButton?()
        }

        self.conversationHeader.didSelect { [unowned self] in
            self.didTapConversationTitle?()
        }

        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }

        self.dataSource.handleDeleteMessage = { [unowned self] message in
            self.conversationController?.deleteMessage(message.id)
        }
    }

    func subscribeToUpdates() {

        KeyboardManager.shared.addKeyboardObservers(with: self.inputAccessoryView)

        KeyboardManager.shared.$isKeyboardShowing
            .mainSink { isShowing in
                self.state = isShowing ? .write : .read
        }.store(in: &self.cancellables)

        self.$state
            .removeDuplicates()
            .mainSink { state in
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

        self.conversationController?.memberEventPublisher.mainSink { [unowned self] _ in
            self.conversationHeader.configure(with: self.conversation)
        }.store(in: &self.cancellables)

        self.conversationController?.typingUsersPublisher.mainSink { [unowned self] users in
            let nonMeUsers = users.filter { user in
                return user.userObjectID != User.current()?.objectId
            }
            self.messageInputAccessoryView.updateTypingActivity(with: nonMeUsers)
        }.store(in: &self.cancellables)

        self.collectionView.publisher(for: \.contentOffset).mainSink { _ in
            if let ip = self.collectionView.getCentermostVisibleIndex(),
                let itemIdendifiter = self.dataSource.itemIdentifier(for: ip) {

                switch itemIdendifiter {
                case .message(let messageID):
                    let messageController = ChatClient.shared.messageController(cid: self.conversation.cid,
                                                                                messageId: messageID)
                    if let message = messageController.message {
                        self.dateLabel.set(date: message.createdAt)
                        self.view.layoutNow()
                    }
                case .loadMore:
                    break
                }
            }
        }.store(in: &self.cancellables)

        self.messageInputAccessoryView.textView.$inputText.mainSink { _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
        }.store(in: &self.cancellables)
    }
}
