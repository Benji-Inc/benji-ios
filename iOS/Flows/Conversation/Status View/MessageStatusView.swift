//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import StreamChat
import Combine

class MessageStatusView: View {

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
    func configure(for message: Message?) {
        guard let message = message else {
            self.readView.reset()
            self.replyView.reset()
            self.layoutNow()
            return
        }

        if let old = self.messageController?.message,
           old.id == message.id,
           old.updatedAt < message.updatedAt {
            self.update(for: message)
        } else if self.messageController.isNil {
            self.update(for: message)
        }
    }

    private func update(for message: Message) {
        self.messageController = ChatClient.shared.messageController(cid: message.cid!, messageId: message.id)
        self.replyView.setReplies(for: message)
        self.readView.configure(for: message)
        self.subscribeToUpdates(for: message)
        self.layoutNow()
    }

    private func subscribeToUpdates(for message: Message) {

        self.messageController?.messageChangePublisher.mainSink { [unowned self] output in
            switch output {
            case .create(_):
                break
            case .update(let new):
                Task {
                    self.configure(for: new)
                }.add(to: self.taskPool)
            case .remove(_):
                break
            }
        }.store(in: &self.cancellables)
    }

    func handleConsumption() {
        guard let message = self.messageController?.message else { return }
        if !message.isFromCurrentUser, !message.isConsumedByMe {
            self.readView.beginConsumption(for: message)
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
        self.readView.reset()
        self.replyView.reset() 
    }
}

private class MessageStatusContainer: View {

    let maxWidth: CGFloat = 100
    let minWidth: CGFloat = 20

    override func initializeSubviews() {
        super.initializeSubviews()

        self.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = Color.border.color.cgColor
        self.layer.borderWidth = 0.25

        self.clipsToBounds = true 
    }
}

private class MessageReadView: MessageStatusContainer {

    let imageView = UIImageView()
    let label = Label(font: .small)
    let progressView = View()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.progressView)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.label)

        self.progressView.width = 1
        self.progressView.set(backgroundColor: .white)
        self.progressView.alpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 18
        self.imageView.pin(.right, offset: .short)
        self.imageView.centerOnY()

        let maxWidth = self.maxWidth - Theme.ContentOffset.short.value.doubled - self.imageView.width
        self.label.setSize(withWidth: maxWidth)
        let offset = self.imageView.width + Theme.ContentOffset.short.value.doubled
        self.label.pin(.right, offset: .custom(offset))
        self.label.centerOnY()

        let width = (Theme.ContentOffset.short.value * 3) + self.imageView.width + self.label.width
        self.width = clamp(width, self.minWidth, self.maxWidth)

        self.progressView.expandToSuperviewHeight()
        self.progressView.pin(.left)
    }

    @MainActor
    func configure(for message: Message) {

        if let state = message.localState {
            switch state {
            case .pendingSync, .syncing:
                self.label.setText("Synching")
            case .syncingFailed, .sendingFailed:
                self.label.setText("Error")
            case .pendingSend, .sending:
                self.label.setText("Sending")
            case .deleting:
                break
            case .deletingFailed:
                break
            }
        } else if message.isConsumed {
            if !message.isFromCurrentUser {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            } else if !message.isConsumedByMe {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            }
        } else {
            self.label.setText("Delivered")
            self.imageView.image = UIImage(named: "checkmark")
        }

        self.layoutNow()
    }

    func beginConsumption(for message: Message) {

        self.progressView.alpha = 0
        self.progressView.width = 0

        let wordDuration: TimeInterval = Double(message.text.wordCount) * 0.2
        let duration: TimeInterval = clamp(wordDuration, 2.0, CGFloat.greatestFiniteMagnitude)
        Task {
            await Task.snooze(seconds: 0.1)
            await UIView.awaitAnimation(with: .custom(duration)) { [unowned self] in
                guard !Task.isCancelled else { return }
                self.progressView.alpha = 0.5
                self.progressView.width = self.width
            }

            guard !Task.isCancelled else { return }
            do {
                try await message.setToConsumed()
            }
            catch {
                logDebug(error)
            }

        }.add(to: self.taskPool)
    }

    func reset() {
        self.label.text = nil
        self.imageView.image = nil

        self.progressView.alpha = 0
        self.progressView.width = 0
    }
}

private class MessageReplyView: MessageStatusContainer {

    let label = Label(font: .small, textColor: .textColor)
    let countLabel = Label(font: .xtraSmall, textColor: .white)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.addSubview(self.countLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countLabel.setSize(withWidth: self.maxWidth)
        self.countLabel.pin(.right, offset: .short)
        self.countLabel.centerOnY()

        if self.countLabel.text.isNil {
            self.width = 0
        } else {
            self.label.setSize(withWidth: self.maxWidth - (Theme.ContentOffset.short.value * 3))
            let offset = (Theme.ContentOffset.short.value * 2) + self.countLabel.width
            self.label.pin(.right, offset: .custom(offset))
            self.label.centerOnY()

            let width = (Theme.ContentOffset.short.value * 3) + self.countLabel.width + self.label.width
            self.width = clamp(width, self.minWidth, self.maxWidth)
        }
    }

    func setReplies(for message: Message) {
        self.label.setText(self.getReplies(for: message))
        if message.replyCount > 0 {
            self.countLabel.setText("\(message.replyCount)")
        } else {
            self.countLabel.text = nil
        }
        self.layoutNow()
    }

    private func getReplies(for message: Message) -> Localized? {
        if message.replyCount == 0 {
            return nil
        } else {
            return "Replies"
        }
    }

    func reset() {
        self.label.text = nil
        self.countLabel.text = nil
    }
}
