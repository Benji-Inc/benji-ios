//
//  ChatChannel+Extensions.swift
//  ChatChannel+Extensions
//
//  Created by Martin Young on 9/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import Localization

extension Conversation {

    enum Role: String {
        case owner
        case member
    }

    /// Returns the conversation with the specified cid using the shared ChatClient.
    static func conversation(_ cid: ConversationId) -> Conversation? {
        return ConversationController.controller(cid).conversation
    }

    var currentRole: Role? {
        return Role(rawValue: self.membership?.memberRole.rawValue ?? "")
    }

    var isOwnedByMe: Bool {
        return self.createdBy?.personId == ChatClient.shared.currentUserId
    }

    var title: String? {
        if let friendlyName = self.name, !friendlyName.isEmpty {
            return localized(friendlyName.capitalized)
        }
        
        return nil 
    }

    var description: Localized {
        let members = self.lastActiveMembers.filter { member in
            return member.personId != ChatClient.shared.currentUserId
        }

        if members.count == 0 {
            return "Just You"
        } else if members.count == 1, let member = members.first {
            return member.name ?? "No name"
        } else {
            return self.displayGroupChat(for: self, with: members)
        }
    }

    func displayGroupChat(for conversation: ChatChannel, with members: [ChatChannelMember]) -> String {
        var text = ""
        for (index, member) in members.enumerated() {
            if index < members.count - 1 {
                text.append(String("\(member.givenName), "))
            } else if index == members.count - 1 && members.count > 1 {
                text.append(String("\(member.givenName)"))
            } else {
                text.append(member.givenName)
            }
        }

        return text
    }

    /// Returns the oldest message that the passed in used has not yet read.
    func getOldestUnreadMessage(withUserID userID: UserId) -> Message? {
        guard let readState = self.reads.first(where: { readState in
            return readState.user.personId == userID
        }) else {
            return nil
        }

        let lastReadDate = readState.lastReadAt

        return self.latestMessages.reversed().first(where: { message in
            return message.createdAt > lastReadDate
        })
    }
}

extension Conversation: MessageSequence {

    var id: String {
        return self.cid.description
    }

    var isFromCurrentUser: Bool {
        return self.isOwnedByMe
    }

    var authorId: String {
        return self.createdBy!.personId
    }

    var attributes: [String : Any]? {
        return nil
    }

    var totalReplyCount: Int {
        return self.latestMessages.count
    }

    var messages: [Messageable] {
        let messageArray = Array(ChatClient.shared.channelController(for: self.cid).messages)
        return messageArray
    }
}
