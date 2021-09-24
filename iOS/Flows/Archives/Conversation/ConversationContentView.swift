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
        self.currentItem = item

        Task {
            await self.display(conversation: item)
        }
    }

    private func display(conversation: ChatChannel) async {
        let members = conversation.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }

        guard self.currentItem?.cid == conversation.cid else { return }

        if let friendlyName = conversation.name, !friendlyName.isEmpty {
            self.label.setText(friendlyName.capitalized)
        } else if members.count == 0 {
            self.label.setText("You")
        } else if members.count == 1, let member = members.first  {
            await self.displayDM(for: conversation, with: member)
        } else {
            self.displayGroupChat(for: conversation, with: members)
        }

        if let msg = conversation.latestMessages.first {
            self.messageLabel.setText(msg.text)
        }

        self.stackedAvatarView.set(items: members)
        self.stackedAvatarView.layoutNow()
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

    private func displayDM(for conversation: ChatChannel, with member: ChatChannelMember) async {
        self.label.setText(member.name)
        self.label.setFont(.largeThin)
        self.setNeedsLayout()
    }

    func displayGroupChat(for conversation: ChatChannel, with members: [ChatChannelMember]) {
        var text = ""
        for (index, member) in members.enumerated() {
            if index < members.count - 1 {
                text.append(String("\(member.givenName), "))
            } else if index == members.count - 1 && members.count > 1 {
                text.append(String("\(member.givenName)"))
            } else {
                text.append(member.givenName)
            }
        }

        self.label.setText(text)
        self.label.setFont(.mediumThin)
        self.layoutNow()
    }
}
