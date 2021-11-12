//
//  ConversationListController+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/12/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationListController = ChatChannelListController
typealias ConversationListQuery = ChannelListQuery

extension ConversationListController {

    var conversations: [Conversation] {
        return Array(self.channels)
    }
}
