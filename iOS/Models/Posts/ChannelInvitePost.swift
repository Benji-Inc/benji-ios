//
//  ChannelInvitePost.swift
//  Ours
//
//  Created by Benji Dodgson on 3/9/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ChannelInvitePost: SystemPost {

    init(with channelSid: String) {
        let type = PostType.channelInvite
        let attributes = ["channelSid": channelSid]
        super.init(author: User.current()!,
                   body: String(),
                   triggerDate: nil,
                   expirationDate: nil,
                   type: type,
                   file: nil,
                   attributes: attributes,
                   priority: type.defaultPriority,
                   duration: type.defaultDuration)
    }
}
