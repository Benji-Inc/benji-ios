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
        self.dataSource.handleDidTapClose = { [unowned self] item in
            self.dataSource.deleteItems([item])
            switch item {
            case .upsell:
                UserDefaultsManager.update(key: .shouldShowGroupsUpsell, with: false)
            case .invest:
                UserDefaultsManager.update(key: .shouldShowInvestUpsell, with: false)
            default:
                break
            }
        }

        self.dataSource.handleLoadMoreMessages = { [unowned self] in
            self.loadMoreConversationsIfNeeded()
        }
        
        self.dataSource.handleCollectionViewTapped = { [unowned self] in
            if self.messageInputController.swipeInputView.textView.isFirstResponder {
                self.messageInputController.swipeInputView.textView.resignFirstResponder()
            } else {
                self.messageInputController.swipeInputView.textView.becomeFirstResponder()
            }
        }
    }

    func subscribeToUIUpdates() {
        self.messageInputController.$inputState
            .removeDuplicates()
            .mainSink { [unowned self] state in
                UIView.animate(withDuration: Theme.animationDurationFast) {
                    self.headerVC.view.alpha = state == .collapsed ? 1.0 : 0.5
                }
            }.store(in: &self.cancellables)
        
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

        self.messageInputController.swipeInputView.textView.$inputText.mainSink { [unowned self] text in
            guard let conversationController = self.getCurrentConversationController() else { return }

            guard conversationController.areTypingEventsEnabled else { return }

            if text.isEmpty {
                conversationController.sendStopTypingEvent()
            } else {
                conversationController.sendKeystrokeEvent()
            }
        }.store(in: &self.cancellables)
    }
}
