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

    private var channel: TCHChannel?

    override func initializeViews() {
        super.initializeViews()

        self.button.set(style: .normal(color: .purple, text: "JOIN"))
    }

    override func configurePost() {
        guard case PostType.channelInvite(let channel) = self.type else { return }
        self.configure(with: channel)
    }

    private func configure(with channel: TCHChannel) {
        self.channel = channel 
        channel.getAuthorAsUser()
            .mainSink(receiveValue: { (user) in
                self.avatarView.set(avatar: user)
                let text = "You have been invited to join \(String(optional: channel.friendlyName)), by \(user.fullName)"
                self.textView.set(localizedText: text)
                self.view.layoutNow()
            }).store(in: &self.cancellables)
    }

    override func didTapButton() {
        guard let channel = self.channel else { return }

        if channel.member(withIdentity: User.current()!.objectId!).isNil {
            channel.join()
                .mainSink { (_) in
                    self.textView.set(localizedText: "Success!")
                    self.button.set(style: .normal(color: .lightPurple, text: "Open"))
                    self.view.layoutNow()
                }.store(in: &self.cancellables)
        } else {
            self.didSelectPost?()
        }
    }
}
