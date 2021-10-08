//
//  ConversationContentView.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import StreamChat

@MainActor
class ConversationContentView: View {

    let stackedAvatarView = StackedAvatarView()
    let label = Label(font: .mediumThin, textColor: .background4)
    let messageLabel = Label(font: .smallBold, textColor: .background4)

    private var cancellables = Set<AnyCancellable>()
    private var currentItem: Conversation?

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.set(backgroundColor: .background3)

        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.label)
        self.addSubview(self.messageLabel)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail

        self.messageLabel.textAlignment = .left
        self.messageLabel.lineBreakMode = .byTruncatingTail

        self.stackedAvatarView.itemHeight = 70
    }

    func configure(with item: Conversation) {
        guard self.currentItem?.title != item.title ||
                self.currentItem?.lastActiveMembers != item.lastActiveMembers ||
                self.currentItem?.latestMessages.first != item.latestMessages.first else { return }

        defer {
            self.currentItem = item
        }

        if self.currentItem?.title != item.title {
            self.label.setText(item.title)
        }

        if self.currentItem?.lastActiveMembers != item.lastActiveMembers {
            let members = item.lastActiveMembers.filter { member in
                return member.id != ChatClient.shared.currentUserId
            }

            if !members.isEmpty {
                self.stackedAvatarView.set(items: members)
            } else {
                self.stackedAvatarView.set(items: [User.current()!])
            }

            self.stackedAvatarView.layoutNow()
        }

        if self.currentItem?.latestMessages.first != item.latestMessages.first {
            if let msg = item.latestMessages.first {
                self.messageLabel.setText(msg.text)
            }
        }

        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.centerOnY()
        self.stackedAvatarView.pin(.left, padding: Theme.contentOffset.half)

        let maxWidth = self.width - Theme.contentOffset - self.stackedAvatarView.width
        self.label.setSize(withWidth: maxWidth)
        self.label.pin(.top, padding: Theme.contentOffset.half)
        self.label.match(.left, to: .right, of: self.stackedAvatarView, offset: Theme.contentOffset.half)

        let maxHeight = self.height - self.label.height - Theme.contentOffset
        self.messageLabel.setSize(withWidth: maxWidth, height: maxHeight)
        self.messageLabel.match(.top, to: .bottom, of: self.label, offset: 4)
        self.messageLabel.match(.left, to: .left, of: self.label)
    }
}
