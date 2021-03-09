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
        case .unreadMessages:
            return 1
        case .channelInvite:
            return 3
        case .connectionRequest:
            return 2
        case .inviteAsk:
            return 6
        case .notificationPermissions:
            return 5
        case .meditation:
            return 7
        }
    }

    var defaultDuration: Int {
        return 5
    }
}
