//
//  CommentsViewController+Extensions.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/20/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import KeyboardManager

extension CommentsViewController {

    func setupInputHandlers() {
        self.dataSource.handleCollectionViewTapped = { [unowned self] in
            if self.messageInputController.swipeInputView.textView.isFirstResponder {
                self.messageInputController.swipeInputView.textView.resignFirstResponder()
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
        guard let controller = self.conversationController else { return }
            controller
            .channelChangePublisher
            .mainSink { [unowned self] _ in
                Task {
                    await self.dataSource.update(with: controller)
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
