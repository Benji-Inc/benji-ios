//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class MessageStatusView: View {

    private var previousStatus: ChatMessageStatus?

    private let readView = MessageReadView()
    private let replyView = MessageReplyView()

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

    func set(status: ChatMessageStatus?) {
        guard let status = status else {
            self.readView.reset()
            self.replyView.reset()
            self.layoutNow()
            return
        }

        guard self.previousStatus != status else { return }

        self.previousStatus = status

        self.replyView.setReplies(for: status.message)
        self.readView.configure(for: status)
        self.layoutNow()
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
    }
}

private class MessageReadView: MessageStatusContainer {

    let imageView = UIImageView()
    let label = Label(font: .small)
    let progressView = UIProgressView()

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.addSubview(self.label)
        self.addSubview(self.progressView)
        self.progressView.isVisible = false
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

        self.progressView.expandToSuperviewSize()
    }

    func configure(for status: ChatMessageStatus) {

        if let state = status.state {
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
        } else if status.isRead {
            self.label.setText("Read")
            self.imageView.image = UIImage(named: "checkmark-double")
        } else {
            self.label.setText("Delivered")
            self.imageView.image = UIImage(named: "checkmark")
        }

        self.layoutNow()
    }

    func reset() {
        self.label.text = nil
        self.imageView.image = nil
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
        self.countLabel.pin(.right, offset: .standard)
        self.countLabel.centerOnY()

        if self.countLabel.text.isNil {
            self.label.setSize(withWidth: self.maxWidth - (Theme.ContentOffset.short.value * 2))

            let width = (Theme.ContentOffset.short.value * 2) + self.label.width
            self.width = clamp(width, self.minWidth, self.maxWidth)

            self.label.centerOnXAndY()
        } else {
            self.label.setSize(withWidth: self.maxWidth - (Theme.ContentOffset.short.value * 3))
            let offset = (Theme.ContentOffset.short.value * 3) + self.countLabel.width
            self.label.pin(.right, offset: .custom(offset))
            self.label.centerOnY()

            let width = (Theme.ContentOffset.short.value * 4) + self.countLabel.width + self.label.width
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

    private func getReplies(for message: Message) -> Localized {
        if message.replyCount == 0 {
            return "No Replies"
        } else {
            return "Replies"
        }
    }

    func reset() {
        self.label.text = nil
        self.countLabel.text = nil
    }
}
