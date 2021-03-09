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

    override func initializeViews() {
        super.initializeViews()

        self.button.set(style: .normal(color: .purple, text: "OPEN"))
    }

    override func didTapButton() {
        self.didSelectPost?()
    }

    override func configurePost() {
        guard let channel = self.post.channel,
              let count = self.post.numberOfUnread else { return }

        self.configure(with: channel, count: count)
    }

    func configure(with channel: TCHChannel, count: Int) {
        channel.getAuthorAsUser()
            .mainSink(receiveValue: { (user) in
                self.avatarView.set(avatar: user)
                if count > 0 {
                    self.textView.set(localizedText: "You have \(String(count)) unread messages in \(String(optional: channel.friendlyName))")
                } else {
                    self.textView.set(localizedText: "Nice job! 🥳 You are all caught up in: \(String(optional: channel.friendlyName))")
                }

                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }
}

