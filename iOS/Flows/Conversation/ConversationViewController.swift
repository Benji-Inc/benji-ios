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

class ConversationViewController: FullScreenViewController,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout,
                                  SwipeableInputAccessoryViewDelegate {
    
    private lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    private lazy var collectionView = ConversationCollectionView()
    private let sendMessageOverlay = ConversationSendOverlayView()
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let conversationHeader = ConversationHeaderView()
    private let dateLabel = ConversationDateLabel()

    var conversation: Conversation! { return self.conversationController?.channel }
    private(set) var conversationController: ChatChannelController?

    // Input handlers
    var onSelectedThread: ((ChannelId, MessageId) -> Void)?
    var didTapMoreButton: CompletionOptional = nil
    var didTapConversationTitle: CompletionOptional = nil

    // Custom Input Accessory View
    lazy var messageInputAccessoryView = ConversationInputAccessoryView(with: self)
    override var inputAccessoryView: UIView? {
        return self.messageInputAccessoryView
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    init(conversation: Conversation?) {
        if let conversation = conversation {
            self.conversationController
            = ChatClient.shared.channelController(for: conversation.cid, messageOrdering: .topToBottom)
        }
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.insertSubview(self.blurView, belowSubview: self.contentContainer)

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
        self.contentContainer.addSubview(self.collectionView)

        self.contentContainer.addSubview(self.conversationHeader)
        self.conversationHeader.configure(with: self.conversation)
        self.conversationHeader.button.didSelect { [unowned self] in
            self.didTapMoreButton?()
        }

        self.conversationHeader.didSelect { [unowned self] in
            self.didTapConversationTitle?()
        }

        self.contentContainer.addSubview(self.dateLabel)

        self.messageInputAccessoryView.textView.$inputText.mainSink { _ in
            guard let enabled = self.conversationController?.areTypingEventsEnabled, enabled else { return }
            self.conversationController?.sendKeystrokeEvent(completion: nil)
        }.store(in: &self.cancellables)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()

        self.conversationHeader.height = self.conversationHeader.stackedAvatarView.itemHeight + Theme.contentOffset
        self.conversationHeader.width = self.view.width - Theme.contentOffset
        self.conversationHeader.pin(.top, padding: Theme.contentOffset.half)
        self.conversationHeader.pin(.left, padding: Theme.contentOffset.half)

        self.dateLabel.setSize(withWidth: self.view.width)
        self.dateLabel.centerOnX()

        self.collectionView.expandToSuperviewWidth()
        let padding = self.dateLabel.height + 40
        self.collectionView.match(.top, to: .bottom, of: self.conversationHeader, offset: padding)
        self.collectionView.height = self.view.height - padding

        // Base the Y position of the date label on the top of the collection view.
        self.dateLabel.match(.bottom, to: .top, of: self.collectionView, offset: -20)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        once(caller: self, token: "initializeCollectionView") {
            Task {
                self.setupInputHandlers()
                // Initialize the datasource before listening for updates to ensure that the sections
                // are set up.
                await self.initializeDataSource()
                self.subscribeToConversationUpdates()
            }
        }
    }
    
    private func setupInputHandlers() {
        self.collectionView.delegate = self
        
        self.collectionView.onDoubleTap { [unowned self] (doubleTap) in
            if self.messageInputAccessoryView.textView.isFirstResponder {
                self.messageInputAccessoryView.textView.resignFirstResponder()
            }
        }
        
        self.dataSource.handleDeleteMessage = { [unowned self] message in
            self.conversationController?.deleteMessage(message.id)
        }
    }

    // MARK: - Message Loading and Updates

    @MainActor
    func initializeDataSource() async {
        guard let controller = self.conversationController else { return }

        // Make sure messages are loaded before initializing the data.
        if let mostRecentMessage = controller.messages.first {
            try? await controller.loadPreviousMessages(before: mostRecentMessage.id)
        }

        let messages = controller.messages
        var snapshot = self.dataSource.snapshot()

        snapshot.appendSections([.conversation(conversation.cid)])
        snapshot.appendItems(messages.asConversationCollectionItems)

        if !controller.hasLoadedAllPreviousMessages {
            snapshot.appendItems([.loadMore], toSection: .conversation(conversation.cid))
        }

        let animationCycle = AnimationCycle(inFromPosition: .right,
                                            outToPosition: .left,
                                            shouldConcatenate: true,
                                            scrollToEnd: false)

        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)
    }

    func subscribeToConversationUpdates() {
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
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let messageItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch messageItem {
        case .message(let messageID):
            self.onSelectedThread?(self.conversation.cid, messageID)
        case .loadMore:
            self.loadMoreMessageIfNeeded()
        }
    }

    /// If true, the conversation controller is currently loading messages.
    @Atomic private var isLoadingMessages = false
    private func loadMoreMessageIfNeeded() {
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

        self.sendMessageOverlay.size = CGSize(width: self.collectionView.width * 0.8,
                                              height: self.collectionView.height * 0.27)
        self.sendMessageOverlay.match(.top, to: .top, of: self.collectionView)
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
