//
//  SwipeableInputAccessoryView.swift
//  Jibber
//
//  Created by Martin Young on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageSendingViewControllerType: UIViewController {
    func set(shouldLayoutForDropZone: Bool)
    func getCurrentMessageSequence() -> MessageSequence?
    func set(messageSequencePreparingToSend: MessageSequence?, reloadData: Bool)
    func sendMessage(_ message: Sendable)
    func createNewConversation(_ sendable: Sendable)
}

protocol MessageSendingCollectionViewType: CollectionView {
    func getMessageDropZoneFrame(convertedTo view: UIView) -> CGRect
    func getDropZoneColor() -> Color?
    func getNewConversationContentOffset() -> CGPoint
}

class SwipeableInputAccessoryMessageSender: SwipeableInputAccessoryViewDelegate {

    /// The type of message send method that the conversation VC is prepped for.
    private enum SendMode {
        /// The message will be sent to currently centered message.
        case message
        /// The message will the first in a new conversation.
        case newConversation
    }

    let viewController: MessageSendingViewControllerType
    let collectionView: MessageSendingCollectionViewType
    let isConversationList: Bool

    /// Shows where a message should be dragged and dropped to send.
    let sendMessageDropZone = MessageDropZoneView()

    private var contentContainer: UIView? {
        return self.collectionView.superview
    }

    init(viewController: MessageSendingViewControllerType,
         collectionView: MessageSendingCollectionViewType,
         isConversationList: Bool) {

        self.viewController = viewController
        self.collectionView = collectionView
        self.isConversationList = isConversationList
    }

    /// The collection view's content offset at the first call to prepare for a swipe. Used to reset the the content offset after a swipe is cancelled.
    private var initialContentOffset: CGPoint?
    /// The last swipe position type that was registersed, if any.
    private var currentSendMode: SendMode?

    // MARK: - SwipeableInputAccessoryViewDelegate

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, swipeIsEnabled isEnabled: Bool) {
        if isEnabled {
            self.showDropZone(for: view)
        } else {
            self.hideDropZone()
        }
    }

    func showDropZone(for view: SwipeableInputAccessoryView) {
        guard self.sendMessageDropZone.superview.isNil, let contentContainer = self.contentContainer else {
            return
        }

        // Animate in the send overlay
        contentContainer.addSubview(self.sendMessageDropZone)
        self.sendMessageDropZone.alpha = 0
        self.sendMessageDropZone.setState(.newMessage, messageColor: self.collectionView.getDropZoneColor())

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageDropZone.alpha = 1
        }

        // Show the send message overlay so the user can see where to drag the message
        let overlayFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: contentContainer)
        self.sendMessageDropZone.frame = overlayFrame

        view.dropZoneFrame = view.convert(self.sendMessageDropZone.bounds, from: self.sendMessageDropZone)

        self.viewController.set(shouldLayoutForDropZone: true)
    }

    func hideDropZone() {
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageDropZone.alpha = 0
        } completion: { didFinish in
            self.sendMessageDropZone.removeFromSuperview()
        }

        self.viewController.set(shouldLayoutForDropZone: false)
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = false

        self.initialContentOffset = self.collectionView.contentOffset
        self.currentSendMode = nil

        guard let currentMessageSequence = self.viewController.getCurrentMessageSequence() else { return }
        self.viewController.set(messageSequencePreparingToSend: currentMessageSequence, reloadData: true)
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdate sendable: Sendable,
                                 withPreviewFrame frame: CGRect) {

        let newSendType = self.getSendMode(forPreviewFrame: frame)

        // Don't do redundant send preparations.
        guard newSendType != self.currentSendMode else { return }

        self.prepareForSend(with: newSendType)
        self.currentSendMode = newSendType
    }

    private func prepareForSend(with position: SendMode) {
        switch position {
        case .message:
            self.sendMessageDropZone.setState(.newMessage,
                                              messageColor: .white)
            if self.isConversationList, let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
        case .newConversation:
            let offset = self.collectionView.getNewConversationContentOffset()
            self.collectionView.setContentOffset(offset, animated: true)
            self.sendMessageDropZone.setState(.newConversation, messageColor: nil)
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 triggeredSendFor sendable: Sendable,
                                 withPreviewFrame frame: CGRect) -> Bool {

        // Ensure that the preview has been dragged far up enough to send.
        let dropZoneFrame = view.dropZoneFrame
        let shouldSend = dropZoneFrame.bottom > frame.centerY

        guard shouldSend else {
            // Reset the collectionview content offset back to where we started.
            if self.isConversationList, let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }

            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageDropZone.setState(.newMessage,
                                                  messageColor: self.collectionView.getDropZoneColor())
            }

            return false
        }

        self.sendMessageDropZone.alpha = 0

        switch self.currentSendMode {
        case .message:
            self.viewController.sendMessage(sendable)
        case .newConversation:
            self.viewController.createNewConversation(sendable)
        case .none:
            return false
        }

        return true
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didFinishSwipeSendingSendable didSend: Bool) {

        self.collectionView.isUserInteractionEnabled = true

        self.viewController.set(messageSequencePreparingToSend: nil, reloadData: !didSend)
    }

    /// Gets the send position for the given preview view frame.
    private func getSendMode(forPreviewFrame frame: CGRect) -> SendMode {
        guard self.isConversationList else { return .message}

        guard let contentContainer = self.contentContainer else {
            return .message
        }

        switch self.currentSendMode {
        case .message, .none:
            // If we're in the message mode, switch to newConversation when the user
            // has dragged far enough to the right.
            if frame.right > contentContainer.width - 10 {
                return .newConversation
            } else {
                return .message
            }
        case .newConversation:
            // If we're in newConversation mode, switch to newMessage mode when the user drags
            // far enough to the left.
            if frame.left < 10 {
                return .message
            } else {
                return .newConversation
            }
        }
    }
}