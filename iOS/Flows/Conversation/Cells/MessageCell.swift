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

@MainActor
protocol MesssageCellDelegate: AnyObject {
    func messageCell(_ cell: MessageCell, didTapMessage messageInfo: (ConversationId, MessageId))
    func messageCell(_ cell: MessageCell, didTapEditMessage messageInfo: (ConversationId, MessageId))
    func messageCell(_ cell: MessageCell, didTapAttachmentForMessage messageInfo: (ConversationId, MessageId))
}

struct MessageDetailState: Equatable {
    var areDetailsFullyVisible: Bool = false
}

/// A cell for displaying individual messages, author and reactions.
class MessageCell: UICollectionViewCell {

    weak var delegate: MesssageCellDelegate?

    @ObservedObject var messageState = MessageDetailViewState(message: nil)

    let content = MessageContentView()
    private var footerView = MessageFooterView()
    
    var shouldShowDetailBar: Bool = true

    @Published private(set) var messageDetailState = MessageDetailState()
    private var conversationsManagerSubscription: AnyCancellable?

    // Context menu
    private lazy var contextMenuDelegate = MessageCellContextMenuDelegate(messageCell: self)

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

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self.contextMenuDelegate)
        self.content.bubbleView.addInteraction(contextMenuInteraction)

        self.content.imageView.didSelect { [unowned self] in
            guard let message = self.messageState.message else { return }

            self.delegate?.messageCell(self, didTapAttachmentForMessage: (message.streamCid, message.id))
        }
        
        self.contentView.addSubview(self.footerView)

        self.conversationsManagerSubscription = ConversationsManager.shared.$activeConversation
            .removeDuplicates()
            .mainSink { [unowned self] activeConversation in
                // If this cell's conversation becomes active,
                // then start message consumption if needed.
                self.handleDetailVisibility(areDetailsFullyVisible: self.footerView.alpha == 1)
            }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.footerView.width = self.contentView.width - Theme.ContentOffset.long.value.doubled
        self.footerView.height = MessageFooterView.height
        self.footerView.centerOnX()
        self.footerView.pin(.bottom)

        self.content.expandToSuperviewWidth()
        self.content.pin(.top)
        self.content.expand(.bottom, to: self.footerView.top, offset: -Theme.ContentOffset.short.value)
    }

    // MARK: Configuration

    func configure(with message: Messageable) {
        self.content.configure(with: message)
        
        self.messageState.message = message
        
        self.footerView.configure(for: message)
        self.footerView.isVisible = self.shouldShowDetailBar

        self.subscribeToUpdates(for: message)
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

        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.footerView.alpha = messageLayoutAttributes.detailAlpha

        let areDetailsFullyVisible = messageLayoutAttributes.detailAlpha == 1 && self.shouldShowDetailBar
        self.messageDetailState = MessageDetailState(areDetailsFullyVisible: areDetailsFullyVisible)

        self.handleDetailVisibility(areDetailsFullyVisible: areDetailsFullyVisible)
    }

    private var messageController: MessageController?
    private var messageSubscriptions: Set<AnyCancellable> = []
    private var messageTasks = TaskPool()

    private func subscribeToUpdates(for messageable: Messageable) {
        if messageable.id != self.messageController?.messageId {
            self.messageController = ChatClient.shared.messageController(for: messageable)
        }

        self.messageController?.reactionsPublisher
            .mainSink(receiveValue: { [unowned self] _ in
                Task {
                    await self.refreshFooter()
                }.add(to: self.messageTasks)
            }).store(in: &self.messageSubscriptions)

        self.messageController?.repliesChangesPublisher
            .mainSink(receiveValue: { [unowned self] _ in
                Task {
                    await self.refreshFooter()
                }.add(to: self.messageTasks)
            }).store(in: &self.messageSubscriptions)
    }

    /// Gets the latest state of the message and updates the footer with that new state.
    private func refreshFooter() async {
        try? await self.messageController?.synchronize()

        guard !Task.isCancelled else { return }

        guard let message = self.messageController?.message else { return }
        self.footerView.configure(for: message)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.messageController = nil
        self.messageSubscriptions.removeAll()
        self.messageTasks.cancelAndRemoveAll()
    }

    // MARK: - Message Detail Tasks

    /// A pool of tasks related to updating the message details.
    private var messageDetailTasks = TaskPool()

    /// Handles changes to the message detail view's visibility.
    private func handleDetailVisibility(areDetailsFullyVisible: Bool) {
        // If the detail visibility changes for a message, we always want to cancel its tasks.
        self.messageDetailTasks.cancelAndRemoveAll()

        guard let messageable = self.messageState.message,
              let cid = try? ConversationId(cid: messageable.conversationId) else { return }

        // If this item is showing its details, we may want to start the consumption process for it.
        guard areDetailsFullyVisible, ChatUser.currentUserRole != .anonymous else { return }

        // Don't consume messages unless they're a part of the active conversation.
        if ConversationsManager.shared.activeConversation?.cid == cid {
            self.startConsumptionTaskIfNeeded(for: messageable)
        }
    }

    /// If necessary for the message, starts a task that sets the delivery status to reading, then consumes the message after a delay.
    private func startConsumptionTaskIfNeeded(for messageable: Messageable) {
        guard messageable.canBeConsumed else { return }

        Task {
            await Task.snooze(seconds: 2)
            guard !Task.isCancelled else { return }

            try? await messageable.setToConsumed()
        }.add(to: self.messageDetailTasks)
    }
}

// MARK: - Helper Functions

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
