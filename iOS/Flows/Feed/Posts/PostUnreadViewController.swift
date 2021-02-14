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

    let textView = FeedTextView()
    let avatarView = AvatarView()
    let button = Button()

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.avatarView)
        self.container.addSubview(self.button)

        self.button.set(style: .normal(color: .purple, text: "OPEN"))
        self.button.didSelect { [unowned self] in
            self.didSelect?()
        }
    }

    func configure(with channel: TCHChannel, count: Int) {
        channel.getAuthorAsUser()
            .mainSink(receiveValue: { (user) in
                self.avatarView.set(avatar: user)
                self.textView.set(localizedText: "You have \(String(count)) unread messages in \(String(optional: channel.friendlyName))")
                self.container.layoutNow()
            }).store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.top = self.container.height * 0.3

        self.textView.setSize(withWidth: self.container.width * 0.9)
        self.textView.centerOnX()
        self.textView.top = self.avatarView.bottom + Theme.contentOffset

        self.button.setSize(with: self.container.width)
        self.button.centerOnX()
        self.button.bottom = self.container.height - Theme.contentOffset
    }
}

