//
//  ConversationContentView.swift
//  Ours
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

    private var cancellables = Set<AnyCancellable>()
    private var currentItem: Conversation?

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    override func initializeSubviews() {
        super.initializeSubviews()

        self.addSubview(self.stackedAvatarView)
        self.addSubview(self.label)
        self.label.textAlignment = .left
        self.label.lineBreakMode = .byTruncatingTail
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

        if let friendlyName = conversation.name {
            self.label.setText(friendlyName.capitalized)
        } else if members.count == 0 {
            self.label.setText("You")
        } else if members.count == 1, let member = members.first  {
            await self.displayDM(for: conversation, with: member)
        } else {
            self.displayGroupChat(for: conversation, with: members)
        }

        self.stackedAvatarView.set(items: members)
        self.stackedAvatarView.layoutNow()
        self.layoutNow()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.pin(.top, padding: Theme.contentOffset.half)
        self.stackedAvatarView.pin(.left, padding: Theme.contentOffset.half)

        let maxWidth = self.width - Theme.contentOffset
        self.label.setSize(withWidth: maxWidth)

        self.label.pin(.bottom, padding: Theme.contentOffset.half)
        self.label.pin(.left, padding: Theme.contentOffset.half)
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
