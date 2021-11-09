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
    private let sendMessageOverlay = ConversationSendOverlayView()
    
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
            // Add query that loads all messages including the one with the messageId passed in
            let query: ChannelListQuery? = nil
            self.conversationController = ChatClient.shared.channelController(for: conversation.cid,
                                                                                 channelListQuery: query,
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
                                  offset: -10)
        self.collectionView.height = self.contentContainer.height - 96
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

        UIView.animate(withDuration: Theme.animationDuration) {
            self.view.layoutNow()
        }
    }

    func updateCenterMostCell() {
        if let cell = self.collectionView.getCentermostVisibleCell() as? ConversationMessageCell {
            self.didCenterOnCell = cell
        }
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        guard let controller = self.conversationController else { return }

        if let messageId = self.startingMessageId {
            try? await controller.loadPreviousMessages(before: messageId)
        }
        // Make sure messages are loaded before initializing the data.
        else if let mostRecentMessage = controller.messages.first {
            try? await controller.loadPreviousMessages(before: mostRecentMessage.id)
        }

        let messages = controller.messages
        var snapshot = self.dataSource.snapshot()

        let section = ConversationSection(cid: controller.cid)
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

        self.updateCenterMostCell()
    }

    private func getIntialIndexPath() -> IndexPath? {
        if let messages = self.conversationController?.conversation.latestMessages,
           let messageId = self.startingMessageId,
            let message = messages.first(where: { message in
               return message.id == messageId
           }),
            let index = messages.firstIndex(of: message) {
            return IndexPath(item: index, section: 0)
        } else {
            return self.getFirstUnreadIndexPath()
        }
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

    /// The collection view's content offset at the first call to prepare for a swipe. Used to reset the the content offset after a swipe is cancelled.
    private var initialContentOffset: CGPoint?
    /// The last swipe position type that was registersed, if any.
    private var lastPreparedPosition: SwipeableInputAccessoryView.SendPosition?

    func swipeableInputAccessoryDidBeginSwipe(_ view: SwipeableInputAccessoryView) {
        self.initialContentOffset = self.collectionView.contentOffset
        self.lastPreparedPosition = nil

        self.collectionView.isUserInteractionEnabled = false

        // Animate in the send overlay
        self.contentContainer.addSubview(self.sendMessageOverlay)
        self.sendMessageOverlay.alpha = 0
        self.sendMessageOverlay.setState(nil)
        UIView.animate(withDuration: Theme.animationDuration) {
            self.sendMessageOverlay.alpha = 1
        }

        // Show the send message overlay so the user can see where to drag the message
        let overlayFrame = self.collectionView.getMessageOverlayFrame(convertedTo: self.contentContainer)
        self.sendMessageOverlay.frame = overlayFrame

        view.targetRect = view.convert(self.sendMessageOverlay.bounds, from: self.sendMessageOverlay)

        self.sendMessageOverlay.centerOnX()
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didPrepare sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition) {

        // Alpha out the collection view to let the user know they can send a message from this position.
        UIView.animate(withDuration: Theme.animationDuration) {
            self.collectionView.alpha = 0.5
        }

        switch position {
        case .left, .middle:
            // Avoid animating content offset twice for redundant states
            guard !self.lastPreparedPosition.equalsOneOf(these: .left, .middle) else { break }

            self.sendMessageOverlay.setState(.reply)
            if let initialContentOffset = self.initialContentOffset {
                self.collectionView.setContentOffset(initialContentOffset, animated: true)
            }
        case .right:
            let newXOffset
            = -self.collectionView.width + self.collectionView.conversationLayout.minimumLineSpacing

            self.sendMessageOverlay.setState(.newMessage)
            self.collectionView.setContentOffset(CGPoint(x: newXOffset, y: 0), animated: true)
        }

        self.lastPreparedPosition = position
    }

    func swipeableInputAccessoryDidUnprepareSendable(_ view: SwipeableInputAccessoryView) {
        self.sendMessageOverlay.setState(nil)
        UIView.animate(withDuration: Theme.animationDuration) {
            self.collectionView.alpha = 1
        }

        guard let initialContentOffset = self.initialContentOffset else { return }
        self.collectionView.setContentOffset(initialContentOffset, animated: true)
    }

    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView,
                                 didConfirm sendable: Sendable,
                                 at position: SwipeableInputAccessoryView.SendPosition) {

        guard let currentIndexPath = self.collectionView.getCentermostVisibleIndex(),
              let currentItem = self.dataSource.itemIdentifier(for: currentIndexPath),
              case let .message(messageID) = currentItem else {

                  // If there is no current message to reply to, assume we're sending a new message
                  Task {
                      await self.send(sendable)
                  }
                  return
              }

        switch position {
        case .left, .middle:
            Task {
                await self.reply(to: messageID, sendable: sendable)
            }
        case .right:
            Task {
                await self.send(sendable)
            }
        }
    }

    func swipeableInputAccessoryDidFinishSwipe(_ view: SwipeableInputAccessoryView) {
        self.collectionView.isUserInteractionEnabled = true

        UIView.animate(withDuration: Theme.animationDuration) {
            self.collectionView.alpha = 1
            self.sendMessageOverlay.alpha = 0
        } completion: { didFinish in
            self.sendMessageOverlay.removeFromSuperview()
        }
    }

    // MARK: - Send Message Functions
    private func send(_ sendable: Sendable) async {
        do {
            try await self.conversationController?.createNewMessage(with: sendable)
        } catch {
            logDebug(error)
        }
    }
    
    private func reply(to messageID: MessageId, sendable: Sendable) async {
        do {
            try await self.conversationController?.createNewReply(for: messageID, with: sendable)
        } catch {
            logDebug(error)
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
