//
//  ConversationViewController.swift
//  ConversationViewController
//
//  Created by Martin Young on 9/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import UIKit
import SwiftUI

enum ConversationUIState {
    case read // Keyboard is NOT shown
    case write // Keyboard IS shown
}

class ConversationViewController: FullScreenViewController,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout,
                                  SwipeableInputAccessoryViewDelegate {

    lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    lazy var collectionView = ConversationCollectionView()
    /// Denotes where a message should be dragged and dropped to send.
    private let sendMessageOverlay = MessageDropZoneView()
    
    let conversationHeader = ConversationHeaderView()

    var conversation: Conversation! { return self.conversationController?.channel }
    private(set) var conversationController: ChatChannelController?

    // Input handlers
    var onSelectedThread: ((ChannelId, MessageId) -> Void)?
    
    @Published var didCenterOnCell: ConversationMessageCell? = nil

    // Custom Input Accessory View
    lazy var messageInputAccessoryView: ConversationInputAccessoryView = {
        let view: ConversationInputAccessoryView = ConversationInputAccessoryView.fromNib()
        view.delegate = self
        view.conversation = self.conversation
        return view
    }()
    
    override var inputAccessoryView: UIView? {
        return self.presentedViewController.isNil ? self.messageInputAccessoryView : nil 
    }

    override var canBecomeFirstResponder: Bool {
        return self.presentedViewController.isNil
    }

    @Published var state: ConversationUIState = .read
    private let startingMessageId: MessageId?
    
    init(conversation: Conversation?, startingMessageId messageId: MessageId?) {
        self.startingMessageId = messageId

        if let conversation = conversation {
            self.conversationController = ChatClient.shared.channelController(for: conversation.cid,
                                                                                 channelListQuery: nil,
                                                                                 messageOrdering: .topToBottom)
        }
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()

        self.contentContainer.addSubview(self.collectionView)
        self.collectionView.delegate = self

        self.contentContainer.addSubview(self.conversationHeader)
        self.conversationHeader.configure(with: self.conversation)

        self.subscribeToKeyboardUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        switch self.state {
        case .read:
            self.conversationHeader.height = 96
        case .write:
            self.conversationHeader.height = 60
        }

        self.conversationHeader.pinToSafeArea(.top, padding: Theme.contentOffset)
        self.conversationHeader.expandToSuperviewWidth()

        self.collectionView.expandToSuperviewWidth()
        self.collectionView.match(.top,
                                  to: .bottom,
                                  of: self.conversationHeader,
                                  offset: -16)
        self.collectionView.height = self.contentContainer.height - 96

        // If we're in the write mode, adjust the position of the collectionview to
        // accomodate the text input, if necessary.
        if self.state == .write {
            self.collectionView.top += self.getCollectionViewYOffset()
        }
    }

    /// Returns how much the collection view y position should  be adjusted to ensure that the text message input
    /// and message drop zone don't overlap.
    private func getCollectionViewYOffset() -> CGFloat {
        let dropZoneFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: self.contentContainer)
        let textView: InputTextView = self.messageInputAccessoryView.textView
        let textViewFrame = textView.convert(textView.bounds, to: self.contentContainer)

        let overlapAmount = dropZoneFrame.bottom + Theme.contentOffset - textViewFrame.top
        return -clamp(overlapAmount, min: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.resignFirstResponder()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        ConversationsManager.shared.activeConversations.remove(object: self.conversation)
        KeyboardManager.shared.reset()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        once(caller: self, token: "initializeCollectionView") {
            Task {
                self.setupInputHandlers()
                // Initialize the datasource before listening for updates to ensure that the sections
                // are set up.
                await self.initializeDataSource()
                self.subscribeToUpdates()

                // Mark the conversation as read if we're looking at the latest message.
                if self.collectionView.contentOffset.x < 0 {
                    await self.markConversationReadIfNeeded()
                }
            }
        }
    }

    func updateUI(for state: ConversationUIState) {
        guard self.presentedViewController.isNil else { return }

        self.conversationHeader.update(for: state)

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.view.layoutNow()
        }
    }

    func updateCenterMostCell() {
        guard let cell = self.collectionView.getCentermostVisibleCell() as? ConversationMessageCell else {
            return
        }
        self.didCenterOnCell = cell

        // If there's a centered cell, update the layout
        if self.collectionView.centerIndexPath().exists {
            UIView.animate(withDuration: Theme.animationDurationFast) {
                self.view.layoutNow()
            }
        }
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        guard let controller = self.conversationController else { return }

        var messageController: MessageController?

        if let messageId = self.startingMessageId {
            var messageIdToLoad = messageId
            messageController = ChatClient.shared.messageController(cid: self.conversation.cid,
                                                                    messageId: messageId)
            if let parentId = messageController?.message?.parentMessageId {
                messageIdToLoad = parentId
            }

            try? await controller.loadPreviousMessages(including: messageIdToLoad)

            if messageController!.message!.parentMessageId.exists {
                try? await messageController?.loadPreviousReplies(including: messageId)
            }
        }
        // Make sure messages are loaded before initializing the data.
        else if let mostRecentMessage = controller.messages.first {
            try? await controller.loadPreviousMessages(before: mostRecentMessage.id)
        }

        let messages = controller.messages
        var snapshot = self.dataSource.snapshot()

        let section = ConversationSection(sectionID: controller.cid!.description)
        snapshot.appendSections([section])
        snapshot.appendItems(messages.asConversationCollectionItems)

        if !controller.hasLoadedAllPreviousMessages && messages.count > 0 {
            snapshot.appendItems([.loadMore], toSection: section)
        }

        let initialIndexPath = self.getIntialIndexPath()
        let animationCycle = AnimationCycle(inFromPosition: .right,
                                            outToPosition: .left,
                                            shouldConcatenate: true,
                                            scrollToIndexPath: initialIndexPath)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)

        //If startingMessage is a reply OR has replies, then open thread
        if let msg = messageController?.message {
            if msg.parentMessageId.exists || msg.replyCount > 0 {
                self.onSelectedThread?(self.conversation.cid, msg.id)
            }
        }

        self.updateCenterMostCell()
    }

    private func getIntialIndexPath() -> IndexPath? {
        if let messageId = self.startingMessageId {
            return self.getMessageIndexPath(with: messageId)
        } else {
            return self.getFirstUnreadIndexPath()
        }
    }

    func getMessageIndexPath(with msgId: MessageId) -> IndexPath? {
        let controller = ChatClient.shared.messageController(cid: self.conversation.cid, messageId: msgId)
        let messages = Array(self.conversationController!.messages)
        let index = messages.firstIndex { msg in
            return msg.id == controller.messageId || msg.id == controller.message?.parentMessageId
        }

        if let i = index {
            return IndexPath(item: i, section: 0)
        }

        return nil
    }

    private func getFirstUnreadIndexPath() -> IndexPath? {
        guard let conversation = self.conversationController?.conversation else { return nil }

        guard let userID = ChatClient.shared.currentUserId,
              let message = conversation.getOldestUnreadMessage(withUserID: userID) else {
            return nil
        }

        guard let index = conversation.latestMessages.firstIndex(of: message) else { return nil }
        return IndexPath(item: index, section: 0)
    }
    
    // MARK: - UICollection Input Handlers

    /// If true, the conversation controller is currently loading messages.
    @Atomic private var isLoadingMessages = false
    func loadMoreMessageIfNeeded() {
        guard let conversationController = self.conversationController else { return }

        // If all the messages are loaded, there's no need to fetch more.
        guard !conversationController.hasLoadedAllPreviousMessages else { return }

        Task {
            guard !isLoadingMessages else { return }

            self.isLoadingMessages = true
            do {
                let oldestMessageID = conversationController.messages.last?.id
                try await conversationController.loadPreviousMessages(before: oldestMessageID)
            } catch {
                logDebug(error)
            }
            self.isLoadingMessages = false
        }
    }

    // MARK: - UIScrollViewDelegate
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        // Always scroll so that a cell is centered when we stop scrolling.
        var newXOffset = CGFloat.greatestFiniteMagnitude
        let targetOffset = targetContentOffset.pointee
        
        let targetRect = CGRect(x: targetOffset.x,
                                y: targetOffset.y,
                                width: scrollView.width,
                                height: scrollView.height)
        
        let layout = self.collectionView.conversationLayout
        guard let layoutAttributes = layout.layoutAttributesForElements(in: targetRect) else { return }
        
        // Find the item whose center is closest to the proposed offset and set that as the new scroll target
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - targetOffset.x) < abs(newXOffset - targetOffset.x) {
                newXOffset = possibleNewOffset
            }
        }
        
        targetContentOffset.pointee = CGPoint(x: newXOffset, y: targetOffset.y)
        
        self.updateCenterMostCell()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.updateCenterMostCell()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateCenterMostCell()

        guard self.conversation.isUnread else { return }
        // Once the user sees the latest message, set the conversation as read.
        guard scrollView.contentOffset.x < 0 else { return }

        Task {
            await self.markConversationReadIfNeeded()
        }
    }

    @Atomic private var isSettingChannelRead = false
    private func markConversationReadIfNeeded() async {
        guard self.conversation.isUnread,
              let conversationController = self.conversationController else { return }

        self.isSettingChannelRead = true
        do {
            try await conversationController.markRead()
        } catch {
            logDebug(error)
        }
        self.isSettingChannelRead = false
    }

    // MARK: - SwipeableInputAccessoryViewDelegate

    /// The type of message send method that the conversation VC is prepped for.
    private enum SendMode {
        /// The message will be sent as a reply to the currently centered message.
        case reply
        /// The message will be sent as a new message.
        case newMessage
    }

    /// The collection view's content offset at the first call to prepare for a swipe. Used to reset the the content offset after a swipe is cancelled.
    private var initialContentOffset: CGPoint?
    /// The last swipe position type that was registersed, if any.
    private var currentSendMode: SendMode?

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.initialContentOffset = self.collectionView.contentOffset
        self.currentSendMode = nil

        self.collectionView.isUserInteractionEnabled = false

        // Animate in the send overlay
        self.contentContainer.addSubview(self.sendMessageOverlay)
        self.sendMessageOverlay.alpha = 0
        self.sendMessageOverlay.setState(nil)
        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageOverlay.alpha = 1
        }

        // Show the send message overlay so the user can see where to drag the message
        let overlayFrame = self.collectionView.getMessageDropZoneFrame(convertedTo: self.contentContainer)
        self.sendMessageOverlay.frame = overlayFrame

        view.dropZoneFrame = view.convert(self.sendMessageOverlay.bounds, from: self.sendMessageOverlay)

        self.sendMessageOverlay.centerOnX()
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
        case .reply:
            self.sendMessageOverlay.setState(.reply)
            if let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
        case .newMessage:
            let newXOffset
            = -self.collectionView.width + self.collectionView.conversationLayout.minimumLineSpacing

            self.sendMessageOverlay.setState(.newMessage)
            self.collectionView.setContentOffset(CGPoint(x: newXOffset, y: 0), animated: true)
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
            return false
        }

        switch self.currentSendMode {
        case .reply:
            guard let currentIndexPath = self.collectionView.getCentermostVisibleIndex(),
                  let currentItem = self.dataSource.itemIdentifier(for: currentIndexPath),
                  case let .messages(messageID) = currentItem else {

                      // If there is no current message to reply to, assume we're sending a new message
                      self.send(sendable)
                      return true
                  }

            self.reply(to: messageID, sendable: sendable)
        case .newMessage:
            self.send(sendable)
        case .none:
            return false
        }

        return true
    }

    func swipeableInputAccessoryDidFinishSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = true

        UIView.animate(withDuration: Theme.animationDurationStandard) {
            self.sendMessageOverlay.alpha = 0
        } completion: { didFinish in
            self.sendMessageOverlay.removeFromSuperview()
        }
    }

    /// Gets the send position for the given preview view frame.
    private func getSendMode(forPreviewFrame frame: CGRect) -> SendMode {
        switch self.currentSendMode {
        case .reply, .none:
            // If we're in the reply mode, switch to newMessage when the user
            // has dragged far enough to the right.
            if frame.right > self.view.width - 10 {
                return .newMessage
            } else {
                return .reply
            }
        case .newMessage:
            // If we're in newMessage mode, switch to reply mode if the user drags far enough to the left.
            if frame.left < 10 {
                return .reply
            } else {
                return .newMessage
            }
        }
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 updatedFrameOf textView: InputTextView) {
        
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.view.layoutNow()
        }
    }

    // MARK: - Send Message Functions

    private func send(_ sendable: Sendable) {
        Task {
            do {
                try await self.conversationController?.createNewMessage(with: sendable)
            } catch {
                logDebug(error)
            }
        }
    }
    
    private func reply(to messageID: MessageId, sendable: Sendable) {
        Task {
            do {
                try await self.conversationController?.createNewReply(for: messageID, with: sendable)
            } catch {
                logDebug(error)
            }
        }
    }
    
    private func update(_ sendable: Sendable) async {
        do {
            try await self.conversationController?.editMessage(with: sendable)
        } catch {
            logDebug(error)
        }
    }
}
