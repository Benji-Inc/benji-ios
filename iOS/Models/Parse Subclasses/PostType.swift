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
    
}
