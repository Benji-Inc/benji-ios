//
//  FeedType.swift
//  Benji
//
//  Created by Benji Dodgson on 6/22/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse

enum PostType: String {

    case timeSaved = "generalUnreadMessages"
    case newChannel
    case unreadMessages = "unreadMessages"
    case channelInvite
    case connectionRequest
    case inviteAsk
    case notificationPermissions
    case meditation

    var defaultPriority: Int {
        switch self {
        case .timeSaved:
            return 0
        case .newChannel:
            return 1
        case .unreadMessages:
            return 2
        case .channelInvite:
            return 3
        case .connectionRequest:
            return 4
        case .inviteAsk:
            return 5
        case .notificationPermissions:
            return 6
        case .meditation:
            return 7
        }
    }

    var defaultDuration: Int {
        return 5
    }
}
