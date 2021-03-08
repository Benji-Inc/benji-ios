//
//  Post+Extensions.swift
//  Ours
//
//  Created by Benji Dodgson on 3/8/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

import TwilioChatClient
import Parse

extension Post {

    var channelId: String? {
        return self.attributes?["channelSid"] as? String
    }

    var numberOfUnread: Int? {
        return self.attributes?["numberOfUnread"] as? Int
    }

    var connection: Connection? {
        return self.attributes?["connection"] as? Connection
    }

    var reservation: Reservation? {
        return self.attributes?["reservation"] as? Reservation
    }
}
