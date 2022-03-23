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

    var handleTappedMessage: ((ConversationId, MessageId) -> Void)?
    var handleEditMessage: ((ConversationId, MessageId) -> Void)?
    var handleTappedAttachment: ((MediaItem) -> Void)?

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

        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        self.content.bubbleView.addInteraction(contextMenuInteraction)

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

        guard newWindow.isNil else { return }

        self.detailVC.removeFromParentAndSuperviewIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard self.window.exists else { return }

        self.parentViewController()?.addChild(viewController: self.detailVC, toView: self.contentView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.content.expandToSuperviewSize()

        self.detailVC.view.expandToSuperviewWidth()
        self.detailVC.view.height = 25
        self.detailVC.view.pin(.bottom, offset: .standard)
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
              let cid = try? ConversationId(cid: messageable.conversationId),
        let message = ChatClient.shared.message(cid: cid, id: messageable.id) else { return }

        // If this item is showing its details, we may want to start the consumption process for it.
        guard areDetailsFullyVisible, ChatUser.currentUserRole != .anonymous else { return }

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

// MARK: - Context Menu

extension MessageCell: UIContextMenuInteractionDelegate {

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil) { () -> UIViewController? in
            guard let message = self.messageState.message else { return nil }
            return MessagePreviewViewController(with: message)
        } actionProvider: { (suggestions) -> UIMenu? in
            return self.makeContextMenu()
        }
    }

    private func makeContextMenu() -> UIMenu {
        guard let message = self.messageState.message as? Message, let cid = message.cid else {
            return UIMenu()
        }

        let neverMind = UIAction(title: "Never Mind", image: UIImage(systemName: "nosign")) { action in }

        let confirmDelete = UIAction(title: "Confirm",
                                     image: UIImage(systemName: "trash"),
                                     attributes: .destructive) { action in
            Task {
                let controller = ChatClient.shared.messageController(cid: cid, messageId: message.id)
                do {
                    try await controller.deleteMessage()
                } catch {
                    logError(error)
                }
            }
        }

        let deleteMenu = UIMenu(title: "Delete Message",
                                image: UIImage(systemName: "trash"),
                                options: .destructive,
                                children: [confirmDelete, neverMind])

        let viewReplies = UIAction(title: "View Replies") { [unowned self] action in
            self.handleTappedMessage?(cid, message.id)
        }

        let edit = UIAction(title: "Edit",
                            image: UIImage(systemName: "pencil.circle")) { [unowned self] action in
            self.handleEditMessage?(cid, message.id)
        }

        let read = UIAction(title: "Set to read",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToRead()
        }

        let unread = UIAction(title: "Set to unread",
                            image: UIImage(systemName: "eyeglasses")) { [unowned self] action in
            self.setToUnread()
        }

        var menuElements: [UIMenuElement] = []

        if !isRelease, message.isFromCurrentUser {
            menuElements.append(deleteMenu)
        }

        if !isRelease, message.isFromCurrentUser {
            menuElements.append(edit)
        }

        if message.isConsumedByMe {
            menuElements.append(unread)
        } else if message.canBeConsumed {
            menuElements.append(read)
        }

        if message.parentMessageId.isNil {
            menuElements.append(viewReplies)
        }

        return UIMenu.init(title: "From: \(message.author.parseUser?.fullName ?? "Unkown")",
                           image: nil,
                           identifier: nil,
                           options: [],
                           children: menuElements)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {

        let params = UIPreviewParameters()
        params.backgroundColor = ThemeColor.clear.color
        params.shadowPath = UIBezierPath(rect: .zero)
        if let bubble = interaction.view as? SpeechBubbleView, let path = bubble.bubbleLayer.path {
            params.visiblePath = UIBezierPath(cgPath: path)
        }
        let preview = UITargetedPreview(view: interaction.view!, parameters: params)
        return preview
    }
}

// MARK: - Message Consumption

extension MessageCell {

    func setToRead() {
        guard let msg = self.messageState.message, msg.canBeConsumed else { return }
        Task {
            try await self.messageState.message?.setToConsumed()
        }
    }

    func setToUnread() {
        guard let msg = self.messageState.message, msg.isConsumedByMe else { return }
        Task {
            try await self.messageState.message?.setToUnconsumed()
        }
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
