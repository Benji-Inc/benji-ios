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

enum FeedType: Comparable {

    case timeSaved(Int)
    case rountine
    case system(SystemMessage)
    case unreadMessages(TCHChannel, Int)
    case channelInvite(TCHChannel)
    case connectionRequest(Connection)
    case inviteAsk
    case notificationPermissions
    case meditation

    var id: String {
        switch self {
        case .timeSaved(_):
            return "intro"
        case .rountine:
            return "routine"
        case .system(_):
            return "system"
        case .unreadMessages(_, _):
            return "unreadMessages"
        case .channelInvite(_):
            return "channelInvite"
        case .inviteAsk:
            return "inviteAsk"
        case .notificationPermissions:
            return "notificationPermissions"
        case .connectionRequest:
            return "connecitonRequest"
        case .meditation:
            return "meditation"
        }
    }

    var priority: Int {
        switch self {
        case .timeSaved(_):
            return 0
        case .rountine:
            return 1
        case .channelInvite(_):
            return 2
        case .unreadMessages(_, _):
            return 3
        case .inviteAsk:
            return 4
        case .notificationPermissions:
            return 5
        case .system(_):
            return 6
        case .connectionRequest(_):
            return 7
        case .meditation:
            return 10
        }
    }

    static func < (lhs: FeedType, rhs: FeedType) -> Bool {
        return lhs.priority < rhs.priority
    }

    static func == (lhs: FeedType, rhs: FeedType) -> Bool {
        return lhs.id == rhs.id
    }
}
