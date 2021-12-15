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
                                             startingReplyId: nil)// "B26BE61F-E5EA-40A4-973E-51D7B54D62FA")
    let messageId: MessageId
    let channelId: ChannelId

    init(with channelId: ChannelId,
         messageId: MessageId,
         router: Router,
         deepLink: DeepLinkable?) {

        self.channelId = channelId
        self.messageId = messageId

        super.init(router: router, deepLink: deepLink)
    }

    override func toPresentable() -> PresentableCoordinator<Void>.DismissableVC {
        return self.threadVC
    }
}
