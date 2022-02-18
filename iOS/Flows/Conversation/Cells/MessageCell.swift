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
    var detailShown: Bool = false
    var isInFocus: Bool = false
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
    @Published private(set) var messageDetailState: MessageDetailState = MessageDetailState()
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
                self.handleDetailsShown(self.detailVC.view.alpha == 1)
            }.store(in: &self.subscriptions)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        self.detailVC.removeFromParentAndSuperviewIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if self.window.exists {
            self.parentViewController()?.addChild(viewController: self.detailVC,
                                                  toView: self.contentView)
        }
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

    var messageController: MessageController?
    var cancellables = Set<AnyCancellable>()

    func configure(with message: Messageable) {
        self.content.configure(with: message)

        self.messageState.message = message

        self.messageController = MessageController.controller(try! ConversationId(cid: message.conversationId),
                                                              messageId: message.id)
        
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
                                         focusAmount: messageLayoutAttributes.sectionFocusAmount,
                                         showBubbleTail: messageLayoutAttributes.shouldShowTail,
                                         tailOrientation: messageLayoutAttributes.bubbleTailOrientation)

        self.content.state = messageLayoutAttributes.state
        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.detailVC.view.height = old_MessageDetailView.height
        self.detailVC.view.alpha = messageLayoutAttributes.detailAlpha

        let areDetailsShown = messageLayoutAttributes.detailAlpha == 1.0 && self.shouldShowDetailBar
        let isInfocus = messageLayoutAttributes.sectionFocusAmount == 1
        self.messageDetailState = MessageDetailState(detailShown: areDetailsShown, isInFocus: isInfocus)
        self.handleDetailsShown(areDetailsShown)
    }

    // MARK: - Message Consumption

    private var consumeMessageTask: Task<Void, Never>?

    private func handleDetailsShown(_ areDetailsShown: Bool) {
        // If the detail visibility changes for a message, we always want to cancel its tasks.
        self.consumeMessageTask?.cancel()
        self.consumeMessageTask = nil

        if !areDetailsShown {
            self.messageState.readingState = .notReading
        }

        // If this item is showing its details, we may want to start the consumption process for it.
        guard areDetailsShown, ChatUser.currentUserRole != .anonymous else { return}

        guard let messageable = self.messageState.message,
              let cid = try? ConversationId(cid: messageable.conversationId) else { return }

        // Don't consume messages unless they're a part of the active conversation.
        guard ConversationsManager.shared.activeConversation?.cid == cid else { return }

        let message = ChatClient.shared.message(cid: cid, id: messageable.id)

        self.startConsumptionIfNeeded(for: message)
    }

    private func startConsumptionIfNeeded(for message: Message) {
        #warning("remove this")
        guard !message.isFromCurrentUser else { return }


        #warning("Restore this!")
//        guard message.canBeConsumed else { return }

        self.consumeMessageTask = Task {
            self.messageState.readingState = .reading
            await Task.snooze(seconds: 2)

            guard !Task.isCancelled else { return }

            try? await message.setToConsumed()
        }
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
