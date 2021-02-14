//
//  FeedChannelInviteView.swift
//  Benji
//
//  Created by Benji Dodgson on 12/7/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization
import Combine

class PostChannelInviteViewController: PostViewController {

    let textView = FeedTextView()
    let avatarView = AvatarView()
    let button = Button()
    var didComplete: CompletionOptional = nil
    private var channel: TCHChannel?

    override func initializeViews() {
        super.initializeViews()

        self.container.addSubview(self.textView)
        self.container.addSubview(self.avatarView)
        self.container.addSubview(self.button)

        self.button.set(style: .normal(color: .purple, text: "JOIN"))
//        self.button.didSelect { [unowned self] in
//            guard let channel = self.channel else { return }
////            self.join(channel: channel)
//        }
    }

    func configure(with channel: TCHChannel) {
        self.channel = channel 
        channel.getAuthorAsUser()
            .mainSink(receiveValue: { (user) in
                self.avatarView.set(avatar: user)
                let text = "You have been invited to join \(String(optional: channel.friendlyName)), by \(user.fullName)"
                self.textView.set(localizedText: text)
                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.avatarView.setSize(for: 100)
        self.avatarView.centerOnX()
        self.avatarView.top = self.view.height * 0.3

        self.textView.setSize(withWidth: self.view.width * 0.9)
        self.textView.centerOnX()
        self.textView.top = self.avatarView.bottom + Theme.contentOffset

        self.button.setSize(with: self.view.width)
        self.button.centerOnX()
        self.button.bottom = self.view.height - Theme.contentOffset
    }
}
