//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Combine
import Localization

class MessageStatusView: BaseView {

    private let readView = MessageReadView()
    private let replyView = MessageReplyView()
    private var messageController: ChatMessageController?

    private var cancellables = Set<AnyCancellable>()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.readView)
        self.addSubview(self.replyView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.replyView.expandToSuperviewHeight()
        self.replyView.pin(.right)
        self.replyView.centerOnY()

        self.readView.expandToSuperviewHeight()
        self.readView.centerOnY()
        let readOffset = Theme.ContentOffset.short.value + self.replyView.width
        self.readView.pin(.right, offset: .custom(readOffset))
    }

    @MainActor
    func configure(for message: Messageable) {
        self.messageController = ChatClient.shared.messageController(for: message)
        
        if let msg = self.messageController?.message {
            self.replyView.setReplies(for: msg)
            self.readView.configure(for: msg)
        }

        // Anonymous users can't set messages as read, so hide the read view for them.
        self.readView.isVisible = ChatUser.currentUserRole != .anonymous

        self.layoutNow()
    }

    func handleConsumption() {
        guard ChatUser.currentUserRole != .anonymous,
        let message = self.messageController?.message else { return }

        self.readView.state = .initial
        
        if !message.isFromCurrentUser,
           !message.isConsumedByMe {
            self.readView.beginConsumption(for: message)
        } else {
            self.resetConsumption()
            self.readView.showRead(with: message)
        }
    }

    func resetConsumption() {
        Task {
            await self.readView.taskPool.cancelAndRemoveAll()
            self.readView.progressView.alpha = 0
            self.readView.progressView.width = 0
        }
    }

    func reset() {
        self.readView.state = .initial
        self.replyView.reset()
        self.layoutNow()
    }
}
