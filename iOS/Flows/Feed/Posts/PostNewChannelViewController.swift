//
//  FeedNewChannelView.swift
//  Benji
//
//  Created by Benji Dodgson on 6/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization
import Combine

class PostNewChannelViewController: PostViewController {

    override func initializeViews() {
        super.initializeViews()

        self.button.set(style: .normal(color: .purple, text: "OPEN"))
    }

    override func didTapButton() {
        self.didFinish?()
    }

    func configure(with channel: DisplayableChannel) {
        guard case ChannelType.channel(let tchChannel) = channel.channelType else { return }
        tchChannel.getAuthorAsUser()
            .mainSink(receiveValue: { (user) in
                self.avatarView.set(avatar: user)
                let message = LocalizedString(id: "", arguments: [user.givenName], default: "Congrats! 🎉 You can now chat with @(name)!")
                self.textView.set(localizedText: message)
                self.container.layoutNow()
            }).store(in: &self.cancellables)
    }
}
