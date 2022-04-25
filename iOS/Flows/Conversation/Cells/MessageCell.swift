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

    private var message: Messageable?

    let content = MessageContentView()
    private var footerView = MessageFooterView()
    
    var shouldShowDetailBar: Bool = true
    var shouldShowReplies: Bool = true {
        didSet {
            self.footerView.replySummary.isVisible = self.shouldShowReplies
        }
    }

    @Published private(set) var messageDetailState = MessageDetailState()
    private var conversationsManagerSubscription: AnyCancellable?

    // Context menu
    private lazy var contextMenuDelegate = MessageContentContextMenuDelegate(content: self.content)

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
        
        self.contentView.addSubview(self.footerView)
        
        self.footerView.replySummary.didSelectEmoji = { [unowned self] emoji in
            self.addReply(with: emoji)
        }
        
        self.footerView.replySummary.didSelectSuggestion = { [unowned self] suggestion in
            guard let cid = self.message?.streamCid, let messageId = self.message?.id else { return }
            switch suggestion {
            case .other:
                self.content.delegate?.messageContent(self.content, didTapViewReplies: (cid, messageId))
            default:
                self.addReply(with: suggestion.text)
            }
        }
        
        self.footerView.replySummary.didTapViewReplies = { [unowned self] in
            guard let cid = self.message?.streamCid, let messageId = self.message?.id else { return }
            self.content.delegate?.messageContent(self.content, didTapViewReplies: (cid, messageId))
        }

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
        self.footerView.height = self.shouldShowReplies ? MessageFooterView.height : MessageFooterView.collapsedHeight
        self.footerView.centerOnX()
        self.footerView.pin(.bottom)
        
        self.content.expandToSuperviewWidth()
        self.content.pin(.top)
        self.content.expand(.bottom, to: self.footerView.top, offset: -Theme.ContentOffset.short.value)
    }

    // MARK: - Touch Handling

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Only respond to touches that are in the visible content areas.
        let contentPoint = self.convert(point, to: self.content)
        let footerPoint = self.convert(point, to: self.footerView)

        return self.content.point(inside: contentPoint, with: event)
        || self.footerView.point(inside: footerPoint, with: event)
    }

    // MARK: Configuration

    func configure(with message: Messageable) {
        self.content.configure(with: message)

        self.content.textView.textColor = self.getTextColor(for: message)
        self.content.imageView.alpha = message.canBeConsumed ? 0 : 1
        self.content.linkView.alpha = message.canBeConsumed ? 0 : 1

        self.message = message
        
        self.footerView.configure(for: message)
        self.footerView.isVisible = self.shouldShowDetailBar

        self.subscribeToUpdatesIfNeeded(for: message)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        // Make sure that the z index is up to date. Sometimes the collectionview layout doesn't
        // update the position even though the attributes changed.
        self.layer.zPosition = CGFloat(layoutAttributes.zIndex)

        guard let messageLayoutAttributes
                = layoutAttributes as? ConversationMessageCellLayoutAttributes else {
            return
        }

        self.content.configureBackground(color: ThemeColor.B6.color,
                                         textColor: self.getTextColor(for: self.message),
                                         brightness: messageLayoutAttributes.brightness,
                                         showBubbleTail: false,
                                         tailOrientation: .down)

        self.content.isUserInteractionEnabled = messageLayoutAttributes.detailAlpha == 1

        self.footerView.alpha = messageLayoutAttributes.detailAlpha

        // Hide the emotions view if the cell is scrolled out of focus.
        if messageLayoutAttributes.detailAlpha < 0.5 && self.content.areEmotionsShown {
            self.content.setEmotions(areShown: false, animated: true)
        }

        let areDetailsFullyVisible = messageLayoutAttributes.detailAlpha == 1 && self.shouldShowDetailBar
        self.messageDetailState = MessageDetailState(areDetailsFullyVisible: areDetailsFullyVisible)

        self.handleDetailVisibility(areDetailsFullyVisible: areDetailsFullyVisible)
    }

    private func getTextColor(for message: Messageable?) -> UIColor {
        if message?.canBeConsumed ?? true {
            return ThemeColor.clear.color
        } else {
            return ThemeColor.white.color
        }
    }

    private var messageController: MessageController?
    private var messageSubscriptions: Set<AnyCancellable> = []
    private var messageTasks = TaskPool()

    private func subscribeToUpdatesIfNeeded(for messageable: Messageable) {
        // If we're already subscribed to message updates, don't do it again.
        guard messageable.id != self.messageController?.messageId else { return }

        self.messageController = ChatClient.shared.messageController(for: messageable)

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

        self.content.imageView.displayable = nil
        self.content.emotionCollectionView.setEmotionsCounts([:], animated: false)
        self.content.setEmotions(areShown: false, animated: false)
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

        guard let messageable = self.message,
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
            guard !Task.isCancelled else { return }

            await self.content.playReadAnimations()

            guard !Task.isCancelled else { return }

            await messageable.setToConsumed()
        }.add(to: self.messageDetailTasks)
    }
    
    private func addReply(with text: String) {
        guard let msg = self.message,
                let controller = ChatClient.shared.messageController(for: msg) else { return }
        
        Task {
            let object = SendableObject(kind: .text(text),
                                        deliveryType: msg.deliveryType,
                                        expression: nil)
            try await controller.createNewReply(with: object)
            
            AnalyticsManager.shared.trackEvent(type: .suggestionSelected, properties: ["value": text])
        }
    }
}
