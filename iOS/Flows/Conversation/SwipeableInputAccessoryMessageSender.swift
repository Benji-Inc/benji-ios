//
//  SwipeableInputAccessoryView.swift
//  Jibber
//
//  Created by Martin Young on 12/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageSendingViewController: UIViewController {
    func createNewConversation(_ sendable: Sendable)
    func reply(to cid: ConversationID, sendable: Sendable)
}

protocol MessageSendingCollectionView: CollectionView {
    func getMessageDropZoneFrame(convertedTo view: UIView) -> CGRect
    func getDropZoneColor() -> Color?
    func getCurrentConversationID() -> ConversationID?
    func getNewConversationContentOffset() -> CGPoint
}

protocol MessageSendingDataSource: AnyObject {
    var isShowingDropZone: Bool { get set }
    func set(conversationPreparingToSend: ConversationID?, reloadData: Bool)
}

class SwipeableInputAccessoryMessageSender: SwipeableInputAccessoryViewDelegate {

    /// The type of message send method that the conversation VC is prepped for.
    private enum SendMode {
        /// The message will be sent to currently centered message.
        case message
        /// The message will the first in a new conversation.
        case newConversation
    }

    let viewController: MessageSendingViewController
    let dataSource: MessageSendingDataSource
    let collectionView: MessageSendingCollectionView

    /// Shows where a message should be dragged and dropped to send.
    let sendMessageDropZone = MessageDropZoneView()

    private var contentContainer: UIView? {
        return self.collectionView.superview
    }

    init(viewController: MessageSendingViewController,
         dataSource: MessageSendingDataSource,
         collectionView: MessageSendingCollectionView) {

        self.viewController = viewController
        self.dataSource = dataSource
        self.collectionView = collectionView
    }

    /// The collection view's content offset at the first call to prepare for a swipe. Used to reset the the content offset after a swipe is cancelled.
    private var initialContentOffset: CGPoint?
    /// The last swipe position type that was registersed, if any.
    private var currentSendMode: SendMode?

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

        self.dataSource.isShowingDropZone = true
    }

    func hideDropZone() {
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageDropZone.alpha = 0
        } completion: { didFinish in
            self.sendMessageDropZone.removeFromSuperview()
        }

        self.dataSource.isShowingDropZone = false
    }

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.initialContentOffset = self.collectionView.contentOffset
        self.currentSendMode = nil

        self.collectionView.isUserInteractionEnabled = false

        if let currentCell = self.collectionView.getCentermostVisibleCell() as? ConversationMessagesCell,
           let cidString = currentCell.conversation?.conversationId,
           let cid = try? ConversationID(cid: cidString) {

            self.dataSource.set(conversationPreparingToSend: cid, reloadData: true)
        }
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
            if let initialContentOffset = self.initialContentOffset {
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
            if let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }

            UIView.animate(withDuration: Theme.animationDurationStandard) {
                self.sendMessageDropZone.setState(.newMessage,
                                                  messageColor: self.collectionView.getDropZoneColor())
            }

            return false
        }

        switch self.currentSendMode {
        case .message:
            guard let cid = self.collectionView.getCurrentConversationID() else {
                // If there is no current message to reply to, assume we're sending a new message
                self.viewController.createNewConversation(sendable)
                return true
            }
            self.sendMessageDropZone.alpha = 0

            self.viewController.reply(to: cid, sendable: sendable)
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

        self.dataSource.set(conversationPreparingToSend: nil, reloadData: !didSend)
    }

    /// Gets the send position for the given preview view frame.
    private func getSendMode(forPreviewFrame frame: CGRect) -> SendMode {
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
