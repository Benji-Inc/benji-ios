//
//  ConversationType.swift
//  Benji
//
//  Created by Benji Dodgson on 6/24/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import TMROLocalization

enum ConversationType: Hashable {

    case system(SystemConversation)
    case conversation(TCHChannel)
    case pending(String)

    var uniqueName: String {
        switch self {
        case .system(let conversation):
            return conversation.uniqueName
        case .conversation(let conversation):
            return String(optional: conversation.friendlyName)
        case .pending(let uniqueName):
            return uniqueName
        }
    }

    var displayName: String {
        switch self {
        case .system(let conversation):
            return conversation.displayName
        case .conversation(let conversation):
            return String(optional: conversation.friendlyName)
        case .pending(_):
            return String()
        }
    }

    var dateUpdated: Date {
        switch self {
        case .system(let systemMessage):
            return systemMessage.timeStampAsDate
        case .conversation(let conversation):
            return conversation.dateUpdatedAsDate ?? Date.distantPast
        case .pending(_):
            return Date()
        }
    }

    var id: String {
        switch self {
        case .system(let systemMessage):
            return systemMessage.id
        case .conversation(let conversation):
            return conversation.id
        case .pending(let uniqueName):
            return uniqueName
        }
    }

    var isFromCurrentUser: Bool {
        switch self {
        case .system(_):
            return true
        case .conversation(let conversation):
            return conversation.createdBy == User.current()?.objectId
        case .pending(_):
            return true 
        }
    }
}
