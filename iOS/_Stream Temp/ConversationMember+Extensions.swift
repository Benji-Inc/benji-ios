//
//  ConversationMember+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias ConversationMember = ChatChannelMember

extension Array where Element == ConversationMember {

    var userIDs: [UserId] {
        return self.compactMap { member in
            return member.id
        }
    }
}
