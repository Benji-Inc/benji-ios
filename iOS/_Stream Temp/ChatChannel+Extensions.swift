//
//  ChatChannel+Extensions.swift
//  ChatChannel+Extensions
//
//  Created by Martin Young on 9/13/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat
import TMROLocalization

typealias Conversation = ChatChannel

extension ChatChannel {

    var isOwnedByMe: Bool {
        return self.createdBy?.id == ChatClient.shared.currentUserId
    }

    var title: String {

        let members = self.lastActiveMembers.filter { member in
            return member.id != ChatClient.shared.currentUserId
        }

        if let friendlyName = self.name, !friendlyName.isEmpty {
            return localized(friendlyName.capitalized)
        } else if members.count == 0 {
            return "You"
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
}
