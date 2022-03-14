//
//  MessageCell.swift
//  Jibber
//
//  Created by Martin Young on 11/1/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import SwiftUI
import StreamChat
import Combine

struct MessageDetailState: Equatable {
    var areDetailsFullyVisible: Bool = false
}

/// A cell for displaying individual messages, author and reactions.
class MessageCell: UICollectionViewCell {

    let content = MessageContentView()

    // Detail View
    @ObservedObject private var messageState = MessageDetailViewState(message: nil)
    private lazy var detailView = MessageDetailView(config: self.messageState)
    private lazy var detailVC = NavBarIgnoringHostingController(rootView: self.detailView)
    var shouldShowDetailBar: Bool = true

    /// If true, this cell's message details are fully visible.
    @Published private(set) var messageDetailState = MessageDetailState()
    private var subscriptions = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initializeViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.initializeViews()
    }

    private func initializeViews() {
        self.contentView.addSubview(self.content)

        ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { [unowned self] activeConversation in
                // If this cell's conversation becomes active,
                // then start message consumption if needed.
                self.handleDetailVisibility(areDetailsFullyVisible: self.detailVC.view.alpha == 1)
            }.store(in: &self.subscriptions)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        self.detailVC.removeFromParentAndSuperviewIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard self.window.exists else { return }

        self.parentViewController()?.addChild(viewController: self.detailVC, toView: self.contentView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.height = 25

        self.content.expandToSuperviewWidth()
        self.content.height
        = self.bounds.height - (self.detailVC.view.height - (self.content.bubbleView.tailLength - Theme.ContentOffset.standard.value))

        if self.content.bubbleView.orientation == .down {
            self.content.pin(.top)
            self.detailVC.view.pin(.bottom)
        } else if self.content.bubbleView.orientation == .up {
            self.detailVC.view.pin(.top)
            self.content.pin(.bottom)
        }
    }

    // MARK: Configuration

    func configure(with message: Messageable) {
        self.content.configure(with: message)
        
        self.messageState.message = message
        self.messageState.deliveryStatus = message.deliveryStatus
        self.messageState.statusText = message.context.displayName
        
        self.detailVC.view.isVisible = self.shouldShowDetailBar
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }
        
        self.content.configureBackground(color: messageLayoutAttributes.backgroundColor,
                                         textColor: messageLayoutAttributes.textColor,
                                         brightness: messageLayoutAttributes.brightness,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)

        self.content.state = messageLayoutAttributes.state
        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.detailVC.view.height = old_MessageDetailView.height
        self.detailVC.view.alpha = messageLayoutAttributes.detailAlpha

        let areDetailsFullyVisible = messageLayoutAttributes.detailAlpha == 1 && self.shouldShowDetailBar
        self.messageDetailState = MessageDetailState(areDetailsFullyVisible: areDetailsFullyVisible)

        self.handleDetailVisibility(areDetailsFullyVisible: areDetailsFullyVisible)
    }

    // MARK: - Message Detail Tasks

    private var messageDetailTasks = TaskPool()

    /// Handles changes to the message detail view's visibility.
    private func handleDetailVisibility(areDetailsFullyVisible: Bool) {
        // If the detail visibility changes for a message, we always want to cancel its tasks.
        self.messageDetailTasks.cancelAndRemoveAll()

        guard let messageable = self.messageState.message,
              let cid = try? ConversationId(cid: messageable.conversationId) else { return }

        // If this item is showing its details, we may want to start the consumption process for it.
        guard areDetailsFullyVisible, ChatUser.currentUserRole != .anonymous else { return }

        let message = ChatClient.shared.message(cid: cid, id: messageable.id)

        // Show the time sent text if needed.
        if message.lastUpdatedAt?.getTimeAgoString() != self.messageState.statusText {
            self.startTimeSentTextTask(for: message)
        }

        // Don't consume messages unless they're a part of the active conversation.
        if ConversationsManager.shared.activeConversation?.cid == cid {
            self.startConsumptionTaskIfNeeded(for: message)
        }
    }

    /// Starts a task that replaces the delivery type text with the last updated text.
    private func startTimeSentTextTask(for message: Message) {
        guard message.deliveryStatus == .sent || message.deliveryStatus == .read else { return }
        
        Task { [weak self] in
            await Task.snooze(seconds: 2)
            guard !Task.isCancelled else { return }
            
            self?.messageState.statusText = message.lastUpdatedAt?.getTimeAgoString() ?? ""
        }.add(to: self.messageDetailTasks)
    }

    /// If necessary for the message, starts a task that sets the delivery status to reading, then consumes the message after a delay.
    private func startConsumptionTaskIfNeeded(for message: Message) {
        guard message.canBeConsumed else { return }

        Task { [weak self] in
            self?.messageState.deliveryStatus = .reading

            await Task.snooze(seconds: 2)
            guard !Task.isCancelled else { return }

            try? await message.setToConsumed()
        }.add(to: self.messageDetailTasks)
    }
}

extension UIView {
    
    // HACK: Accessing a parent view controller from a view is an anti-pattern, but it's extremely convenient
    // in this case where we're assigning a view controller to a cell and need to add it as a childVC.

    /// Used to get the parent view controller of a collection view cell
    fileprivate func parentViewController() -> UIViewController? {
        
        guard let nextResponder = self.next else { return nil }
        
        if let parentViewController = nextResponder as? UIViewController {
            return parentViewController
        } else if let parentView = nextResponder as? UIView {
            return parentView.parentViewController()
        } else {
            return nil;
        }
    }
}
