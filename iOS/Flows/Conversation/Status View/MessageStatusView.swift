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
        guard ChatUser.currentUserRole != .anonymous else { return }

        guard let message = self.messageController?.message,
              !message.isFromCurrentUser,
              !message.isConsumedByMe else { return }

        self.readView.beginConsumption(for: message)
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
        self.layoutNow()
    }
}

private class MessageStatusContainer: BaseView {

    let maxWidth: CGFloat = 200
    let minWidth: CGFloat = 20

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .B1withAlpha)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = ThemeColor.D6withAlpha.color.cgColor
        self.layer.borderWidth = 0.5

        self.clipsToBounds = true 
    }
}

private class MessageReadView: MessageStatusContainer {

    let imageView = UIImageView()
    let label = ThemeLabel(font: .small)
    let progressView = BaseView()
    private(set) var animator: UIViewPropertyAnimator?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.progressView)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.tintColor = ThemeColor.red.color
        self.addSubview(self.label)

        self.progressView.width = 1
        self.progressView.set(backgroundColor: .T1)
        self.progressView.alpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 18

        let maxWidth = self.maxWidth - Theme.ContentOffset.short.value.doubled - self.imageView.width
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.left, offset: .short)
        self.label.centerOnY()

        self.imageView.match(.left, to: .right, of: self.label, offset: .short)
        self.imageView.centerOnY()

        let width: CGFloat
        if self.imageView.image.isNil {
            width = (Theme.ContentOffset.short.value * 2) + self.label.width
        } else {
            width = (Theme.ContentOffset.short.value * 3) + self.imageView.width + self.label.width
        }
        self.width = clamp(width, self.minWidth, self.maxWidth)

        self.progressView.expandToSuperviewHeight()
        self.progressView.pin(.left)
    }

    @MainActor
    func configure(for message: Message) {
        self.reset()

        if message.isConsumed {
            if !message.isFromCurrentUser {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            } else if !message.isConsumedByMe {
                self.label.setText("Read")
                self.imageView.image = UIImage(named: "checkmark-double")
            }
        } else if !message.isConsumed, message.localState.isNil {
            if message.isFromCurrentUser {
                self.label.setText("Delivered \(message.context.displayName)")
            } else {
                self.label.setText("Reading")
            }
            self.imageView.image = UIImage(named: "checkmark")
        } else if let state = message.localState {
            switch state {
            case .pendingSync, .syncing:
                self.label.setText("Syncing")
            case .syncingFailed, .sendingFailed:
                self.label.setText("Error")
            case .pendingSend, .sending:
                self.label.setText("Sending")
                Task {
                    await Task.snooze(seconds: 0.1)
                    guard !Task.isCancelled else { return }
                    if let message = ChatClient.shared.messageController(for: message)?.message {
                        self.configure(for: message)
                    }
                }.add(to: self.taskPool)
            case .deleting:
                break
            case .deletingFailed:
                break
            }
        } else {
            self.label.setText("Error")
        }
        
        self.layoutNow()
    }

    func beginConsumption(for message: Message) {
        guard message.canBeConsumed else { return }

        self.progressView.alpha = 0
        self.progressView.width = 0

        let wordDuration: TimeInterval = Double(message.text.wordCount) * 0.2
        let duration: TimeInterval = clamp(wordDuration, 2.0, CGFloat.greatestFiniteMagnitude)

        self.animator = UIViewPropertyAnimator.init(duration: duration,
                                                    curve: .linear,
                                                    animations: {
            self.progressView.alpha = 0.5
            self.progressView.width = self.width
            self.layoutNow()
        })

        self.animator?.isInterruptible = true
        self.animator?.startAnimation()

        Task {
            await Task.snooze(seconds: duration)
            await UIView.awaitAnimation(with: .fast, animations: {
                self.progressView.alpha = 0
            })
            do {
                guard !Task.isCancelled else { return }
                try await message.setToConsumed()
            }
            catch {
                logError(error)
            }
        }.add(to: self.taskPool)
    }

    func reset() {
        if let animator = self.animator, animator.isRunning {
            animator.stopAnimation(true)
            animator.finishAnimation(at: .start)
        }

        self.label.text = nil
        self.imageView.image = nil

        self.progressView.alpha = 0
        self.progressView.width = 0
    }
}

private class MessageReplyView: MessageStatusContainer {

    let label = ThemeLabel(font: .small)
    let countLabel = ThemeLabel(font: .small, textColor: .D6)

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.label)
        self.addSubview(self.countLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.countLabel.setSize(withWidth: self.maxWidth)
        self.countLabel.centerOnY()

        if self.countLabel.text.isNil {
            self.width = 0
        } else {
            self.label.setSize(withWidth: self.maxWidth - (Theme.ContentOffset.short.value * 3))
            let offset = (Theme.ContentOffset.short.value * 2) + self.countLabel.width
            self.label.centerOnY()

            let width = (Theme.ContentOffset.short.value * 3) + self.countLabel.width + self.label.width
            self.width = clamp(width, self.minWidth, self.maxWidth)

            /// Must set the pin after the width has been set due to it being right aligned
            self.label.pin(.right, offset: .custom(offset))
            self.countLabel.pin(.right, offset: .short)
        }
    }

    func setReplies(for message: Message) {
        self.label.setText(self.getReplies(for: message))
        if message.replyCount > 0 {
            self.countLabel.setText("\(message.replyCount)")
        } else {
            self.countLabel.text = nil
        }
        UIView.animate(withDuration: Theme.animationDurationFast) {
            self.layoutNow()
        }
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
