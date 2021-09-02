//
//  ConversationContentView.swift
//  Ours
//
//  Created by Benji Dodgson on 5/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Combine

@MainActor
class ConversationContentView: View {

    let stackedAvatarView = StackedAvatarView()
    let label = Label(font: .mediumThin, textColor: .background4)

    private var cancellables = Set<AnyCancellable>()
    private var currentItem: DisplayableConversation?

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

    func configure(with item: DisplayableConversation) {
        self.currentItem = item

        switch item.channelType {
        case .channel(let channel):
            Task {
                await self.display(channel: channel)
            }
        default:
            break
        }
    }

    private func display(channel: TCHChannel) async {
        guard let users = try? await channel.getUsers(excludeMe: true) else { return }

        guard self.currentItem?.id == channel.id else { return }

        if let friendlyName = channel.friendlyName {
            self.label.setText(friendlyName.capitalized)
        } else if users.count == 0 {
            self.label.setText("You")
        } else if users.count == 1, let user = users.first(where: { user in
            return user.objectId != User.current()?.objectId
        }) {
            await self.displayDM(for: channel, with: user)
        } else {
            self.displayGroupChat(for: channel, with: users)
        }
        self.stackedAvatarView.set(items: users)
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

    private func displayDM(for channel: TCHChannel, with user: User) async {
        guard let user = try? await user.retrieveDataIfNeeded() else { return }
        self.label.setText(user.givenName)
        self.label.setFont(.largeThin)
        self.setNeedsLayout()
    }

    func displayGroupChat(for channel: TCHChannel, with users: [User]) {
        var text = ""
        for (index, user) in users.enumerated() {
            if index < users.count - 1 {
                text.append(String("\(user.givenName), "))
            } else if index == users.count - 1 && users.count > 1 {
                text.append(String("\(user.givenName)"))
            } else {
                text.append(user.givenName)
            }
        }

        self.label.setText(text)
        self.label.setFont(.mediumThin)
        self.layoutNow()
    }
}
