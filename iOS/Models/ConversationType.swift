//
//  ConversationType.swift
//  Benji
//
//  Created by Benji Dodgson on 6/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization

enum ConversationType: Hashable {

    case system(SystemConversation)
    #warning("Use stream for associated conversation values")
    case conversation
    case pending(String)

    var uniqueName: String {
        switch self {
        case .system(let conversation):
            return conversation.uniqueName
        case .conversation:
            return ""
//            return String(optional: conversation.friendlyName)
        case .pending(let uniqueName):
            return uniqueName
        }
    }

    var displayName: String {
        switch self {
        case .system(let conversation):
            return conversation.displayName
        case .conversation:
            return ""
        case .pending(_):
            return String()
        }
    }

    var dateUpdated: Date {
        switch self {
        case .system(let systemMessage):
            return systemMessage.timeStampAsDate
        case .conversation:
            return Date()
        case .pending(_):
            return Date()
        }
    }

    var id: String {
        switch self {
        case .system(let systemMessage):
            return systemMessage.id
        case .conversation:
            return ""
        case .pending(let uniqueName):
            return uniqueName
        }
    }

    var isFromCurrentUser: Bool {
        switch self {
        case .system(_):
            return true
        case .conversation:
            return true
        case .pending(_):
            return true 
        }
    }
}
