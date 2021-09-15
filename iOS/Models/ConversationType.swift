//
//  ConversationType.swift
//  Benji
//
//  Created by Benji Dodgson on 6/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

enum ConversationType: Hashable {

    case system(SystemConversation)
    case conversation(ChatChannel)

    var id: String {
        switch self {
        case .system(let systemMessage):
            return systemMessage.id
        case .conversation(let conversation):
            return conversation.cid.description
        }
    }

    var displayName: String {
        switch self {
        case .system(let conversation):
            return conversation.displayName
        case .conversation(let conversation):
            return conversation.name ?? String()
        }
    }

    var dateUpdated: Date {
        switch self {
        case .system(let systemMessage):
            return systemMessage.timeStampAsDate
        case .conversation(let conversation):
            return conversation.updatedAt
        }
    }

    var isFromCurrentUser: Bool {
        switch self {
        case .system(_):
            return true
        case .conversation:
            return true
        }
    }
}
