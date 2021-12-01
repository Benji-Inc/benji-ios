//
//  MessageReadView.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/30/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

class MessageReadView: View {

    let imageView = DisplayableImageView()
    let label = Label(font: .regular)
    let progressView = UIProgressView()
    private var previousStatus: ChatMessageStatus?

    override func initializeSubviews() {
        super.initializeSubviews()

        self.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.layer.cornerRadius = Theme.innerCornerRadius
        self.layer.borderColor = Color.border.color.cgColor
        self.layer.borderWidth = 0.25

        self.addSubview(self.imageView)
        self.addSubview(self.label)
        self.addSubview(self.progressView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.squaredSize = 20
        self.pin(.right, offset: .short)

        let maxWidth = self.width - Theme.ContentOffset.short.value.doubled - self.imageView.width
        self.label.setSize(withWidth: maxWidth)
        self.label.match(.right, to: .left, of: self.imageView, offset: .negative(.short))

        self.progressView.expandToSuperviewSize()
    }

    func set(status: ChatMessageStatus?) {
        guard let status = status else {
            self.label.text = nil
            return
        }

        guard self.previousStatus != status else { return }

        self.previousStatus = status

        self.label.setText(self.getText(for: status))
        self.layoutNow()
    }

    private func getText(for status: ChatMessageStatus) -> Localized {

        if let state = status.state {
            switch state {
            case .pendingSync, .syncing:
                return "Syncing"
            case .syncingFailed, .sendingFailed:
                return "Error"
            case .pendingSend, .sending:
                return "Sending"
            case .deleting:
                break
            case .deletingFailed:
                break
            }
        } else if status.isRead {
            return status.message.isFromCurrentUser ? "Read" : "Seen"
        } else {
            return status.message.isFromCurrentUser ? "Sent" : "Received"
        }

        return LocalizedString.empty
    }
}
