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

class ConversationViewController: FullScreenViewController,
                                  UICollectionViewDelegate,
                                  UICollectionViewDelegateFlowLayout {
    
    private lazy var dataSource = ConversationCollectionViewDataSource(collectionView: self.collectionView)
    private var collectionView = CollectionView(layout: new_ConversationCollectionViewLayout())
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let conversationHeader = ConversationHeaderView()

    var conversation: Conversation! { return self.conversationController?.channel }
    private(set) var conversationController: ChatChannelController!
    
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
            = ChatClient.shared.channelController(for: conversation.cid, messageOrdering: .bottomToTop)
        }
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func initializeViews() {
        super.initializeViews()
        
        self.view.insertSubview(self.blurView, belowSubview: self.contentContainer)
        self.contentContainer.addSubview(self.collectionView)
        self.collectionView.decelerationRate = .fast
        self.collectionView.showsHorizontalScrollIndicator = false

        self.contentContainer.addSubview(self.conversationHeader)
        self.conversationHeader.configure(with: self.conversation)
        self.conversationHeader.button.didSelect { [unowned self] in
            self.didTapMoreButton?()
        }

        self.conversationHeader.didSelect { [unowned self] in
            self.didTapConversationTitle?()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.blurView.expandToSuperviewSize()
        self.collectionView.expandToSuperviewSize()

        self.conversationHeader.height = self.conversationHeader.stackedAvatarView.itemHeight + Theme.contentOffset
        self.conversationHeader.width = self.view.width - Theme.contentOffset
        self.conversationHeader.pin(.top, padding: Theme.contentOffset.half)
        self.conversationHeader.pin(.left, padding: Theme.contentOffset.half)
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
            self.conversationController.deleteMessage(message.id)
        }
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
        // If all the messages are loaded, there's no need to fetch more.
        guard !self.conversationController.hasLoadedAllPreviousMessages else { return }

        Task {
            guard !isLoadingMessages else { return }

            self.isLoadingMessages = true
            do {
                let oldestMessageID = self.conversationController.messages.first?.id
                try await self.conversationController.loadPreviousMessages(before: oldestMessageID)
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
        
        let layout = self.collectionView.collectionViewLayout
        guard let layoutAttributes = layout.layoutAttributesForElements(in: targetRect) else {
            return
        }
        
        // Find the item whose center is closest to the proposed offset
        for elementAttributes in layoutAttributes {
            let possibleNewOffset = elementAttributes.frame.centerX - collectionView.halfWidth
            if abs(possibleNewOffset - targetOffset.x) < abs(newXOffset - targetOffset.x) {
                newXOffset = possibleNewOffset
            }
        }
        
        targetContentOffset.pointee = CGPoint(x: newXOffset, y: targetOffset.y)
    }
}

// MARK: - Message Loading and Updates

extension ConversationViewController {
    
    @MainActor
    func initializeDataSource() async {
        guard let controller = self.conversationController else { return }

        // Make sure messages are loaded before initializing the data.
        if let mostRecentMessage = controller.messages.last {
            try? await controller.loadPreviousMessages(before: mostRecentMessage.id)
        }

        let messages = controller.messages
        var snapshot = self.dataSource.snapshot()

        snapshot.appendSections([.loadMore])
        if !controller.hasLoadedAllPreviousMessages {
            snapshot.appendItems([.loadMore], toSection: .loadMore)
        }

        snapshot.appendSections([.conversation(conversation.cid)])
        snapshot.appendItems(messages.asConversationCollectionItems)
        
        let animationCycle = AnimationCycle(inFromPosition: .left,
                                            outToPosition: .right,
                                            shouldConcatenate: true,
                                            scrollToEnd: true)
        
        await self.dataSource.apply(snapshot,
                                    collectionView: self.collectionView,
                                    animationCycle: animationCycle)
    }
    
    func subscribeToConversationUpdates() {
        self.conversationController.messagesChangesPublisher.mainSink { [unowned self] changes in
            Task {
                guard let conversationController = self.conversationController else { return }
                await self.dataSource.update(with: changes,
                                             conversationController: conversationController,
                                             collectionView: self.collectionView)
            }
        }.store(in: &self.cancellables)

        self.conversationController.channelChangePublisher.mainSink { [unowned self] _ in
            self.conversationHeader.configure(with: self.conversation)
        }.store(in: &self.cancellables)

        self.conversationController.memberEventPublisher.mainSink { [unowned self] _ in
            self.conversationHeader.configure(with: self.conversation)
        }.store(in: &self.cancellables)
    }
}

// MARK: - SwipeableInputAccessoryViewDelegate

extension ConversationViewController: SwipeableInputAccessoryViewDelegate {
    
    func swipeableInputAccessory(_ view: SwipeableInputAccessoryView, didConfirm sendable: Sendable) {
        let alert = UIAlertController(title: "Send Method",
                                      message: "Would you like to send your message?",
                                      preferredStyle: .actionSheet)

        if let currentIndexPath = self.collectionView.getCentermostVisibleIndex(),
           let currentItem = self.dataSource.itemIdentifier(for: currentIndexPath) {
            if case let .message(messageID) = currentItem {
                let reply = UIAlertAction(title: "Reply", style: .default) { [unowned self] _ in
                    Task {
                        await self.reply(to: messageID, sendable: sendable)
                    }
                }
                alert.addAction(reply)
            }
        }
        
        let sendNew = UIAlertAction(title: "Send New", style: .default) { [unowned self] _ in
            Task {
                await self.send(sendable)
            }
        }
        alert.addAction(sendNew)
        
        self.present(alert, animated: true)
    }
    
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
