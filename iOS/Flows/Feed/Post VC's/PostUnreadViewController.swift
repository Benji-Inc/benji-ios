//
//  FeedUnreadView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization
import Combine

class PostUnreadViewController: PostViewController {

    private let stackedAvatarView = StackedAvatarView()

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.stackedAvatarView)
        self.stackedAvatarView.itemHeight = 100
        self.button.set(style: .normal(color: .purple, text: "OPEN"))
    }

    override func didTapButton() {
        self.didSelectPost?()
    }

    override func configurePost() {

        guard let channel = self.post.channel,
              let count = self.post.numberOfUnread else {
            print("No channel or post for \(self.post.type.rawValue)")
            return
        }

        self.configure(with: channel, count: count)
    }

    func configure(with channel: TCHChannel, count: Int) {
        channel.getUsers(excludeMe: true)
            .mainSink(receiveValue: { (users) in

                if let friendlyName = channel.friendlyName {
                    self.textView.set(localizedText: "You have \(String(count)) unread messages in \(friendlyName)")
                } else if users.count == 0 {
                    self.textView.set(localizedText: "You have \(String(count)) unread messages.")
                } else if users.count == 1, let user = users.first(where: { user in
                    return user.objectId != User.current()?.objectId
                }) {
                    self.displayDM(for: count, with: user)
                } else {
                    self.displayGroupChat(for: count, with: users)
                }
                self.stackedAvatarView.set(items: users)
                self.stackedAvatarView.layoutNow()
                self.view.layoutNow()

            }).store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.stackedAvatarView.setSize()
        self.stackedAvatarView.centerOnX()
        self.stackedAvatarView.match(.bottom, to: .top, of: self.textView, offset: -Theme.contentOffset)
    }

    private func displayDM(for count: Int, with user: User) {
        user.retrieveDataIfNeeded()
            .mainSink(receiveValue: { user in
                self.textView.set(localizedText: "You have \(String(count)) unread messages with \(user.givenName)")
                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }

    func displayGroupChat(for count: Int, with users: [User]) {
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

        self.textView.set(localizedText: "You have \(String(count)) unread messages with \(text).")
        self.view.layoutNow()
    }
}

