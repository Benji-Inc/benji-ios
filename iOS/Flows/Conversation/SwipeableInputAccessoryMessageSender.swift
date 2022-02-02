//
//  SwipeableInputAccessoryView.swift
//  Jibber
//
//  Created by Martin Young on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageSendingViewControllerType: UIViewController {
    func getCurrentMessageSequence() -> MessageSequence?
    func set(messageSequencePreparingToSend: MessageSequence?)
    func sendMessage(_ message: Sendable)
    func createNewConversation(_ sendable: Sendable)
}

protocol MessageSendingCollectionViewType: CollectionView {
    func getMessageDropZoneFrame(convertedTo view: UIView) -> CGRect
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

    unowned let viewController: MessageSendingViewControllerType
    unowned let collectionView: MessageSendingCollectionViewType
    let isConversationList: Bool
    
    var didTapAvatar: CompletionOptional = nil

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
        // Show the send message overlay so the user can see where to drag the message
        let overlayFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: view)
        view.dropZoneFrame = overlayFrame
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = false

        self.initialContentOffset = self.collectionView.contentOffset
        self.currentSendMode = nil

        guard let currentMessageSequence = self.viewController.getCurrentMessageSequence() else { return }

        self.viewController.set(messageSequencePreparingToSend: currentMessageSequence)
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didUpdatePreviewFrame frame: CGRect,
                                 for sendable: Sendable) {

        let newSendType = self.getSendMode(forPreviewFrame: frame)

        // Don't do redundant send preparations.
        guard newSendType != self.currentSendMode else { return }

        self.prepareForSend(with: newSendType)
        self.currentSendMode = newSendType
    }

    private func prepareForSend(with position: SendMode) {
        switch position {
        case .message:
            if self.isConversationList, let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
        case .newConversation:
            let offset = self.collectionView.getNewConversationContentOffset()
            self.collectionView.setContentOffset(offset, animated: true)
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

            return false
        }

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

        self.viewController.set(messageSequencePreparingToSend: nil)
    }

    /// Gets the send position for the given preview view frame.
    private func getSendMode(forPreviewFrame frame: CGRect) -> SendMode {
        return .message
//        guard self.isConversationList else { return .message }
//
//        guard let contentContainer = self.contentContainer else {
//            return .message
//        }
//
//        switch self.currentSendMode {
//        case .message, .none:
//            // If we're in the message mode, switch to newConversation when the user
//            // has dragged far enough to the right.
//            if frame.right > contentContainer.width - 10 {
//                return .newConversation
//            } else {
//                return .message
//            }
//        case .newConversation:
//            // If we're in newConversation mode, switch to newMessage mode when the user drags
//            // far enough to the left.
//            if frame.left < 10 {
//                return .message
//            } else {
//                return .newConversation
//            }
//        }
    }
    
    func swipeableInputAccessoryDidTapAvatar(_ view: SwipeableInputAccessoryView) {
        self.didTapAvatar?()
    }
}
