//
//  ChatChannel+Extensions.swift
//  ChatChannel+Extensions
//
//  Created by Martin Young on 9/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias Conversation = ChatChannel

extension ChatChannel {

    var isOwnedByMe: Bool {
        return self.createdBy?.id == ChatClient.shared.currentUserId
    }
}
