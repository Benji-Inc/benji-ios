//
//  ConversationThreadCoordinator.swift
//  Jibber
//
//  Created by Benji Dodgson on 11/17/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ThreadCoordinator: PresentableCoordinator<Void> {

    lazy var threadVC = ThreadViewController(channelID: self.channelId,
                                             messageID: self.messageId,
                                             startingReplyId: self.startingReplyId)
    let messageId: MessageId
    let channelId: ChannelId
    let startingReplyId: MessageId?

    init(with channelId: ChannelId,
         messageId: MessageId,
         startingReplyId: MessageId?,
         router: Router,
         deepLink: DeepLinkable?) {

        self.channelId = channelId
        self.messageId = messageId
        self.startingReplyId = startingReplyId

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.threadVC
    }
}
