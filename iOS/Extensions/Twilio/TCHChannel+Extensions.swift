//
//  TCHChannel+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 2/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient
import Parse

extension TCHChannel {

    var id: String {
        return self.sid!
    }

    var isOwnedByMe: Bool {
        guard let currentUser = User.current() else { return false }
        return self.createdBy == currentUser.objectId
    }

    func diffIdentifier() -> NSObjectProtocol {
        return String(optional: self.sid) as NSObjectProtocol
    }

    func getNonMeMembers() -> [TCHMember] {
        if let members = self.members?.membersList() {
            var nonMeMembers: [TCHMember] = []
            members.forEach { (member) in
                if member.identity != User.current()?.objectId {
                    nonMeMembers.append(member)
                }
            }
            return nonMeMembers
        } else {
            return []
        }
    }

    func getUsers(excludeMe: Bool = false) async throws -> [User] {
        let members = self.members?.membersList() ?? []

        var identifiers: [String] = []
        members.forEach { (member) in
            if let identifier = member.identity {
                if identifier == User.current()?.objectId, excludeMe {
                } else {
                    identifiers.append(identifier)
                }
            }
        }
        let users = try await User.localThenNetworkArrayQuery(where: identifiers,
                                                                   isEqual: true,
                                                                   container: .channel(identifier: self.sid!))
        return users
    }

    var channelDescription: String {
        guard let attributes = self.attributes(),
              let text = attributes.dictionary?[ConversationKey.description.rawValue] as? String else { return String() }
        return text
    }

    func join() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.join { result in
                if result.isSuccessful() {
                    continuation.resume(returning: ())
                } else if let e = result.error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(throwing: ClientError.apiError(detail: "Failed to join channel"))
                }
            }
        }
    }
}

extension TCHChannel: Comparable {
    
    public static func < (lhs: TCHChannel, rhs: TCHChannel) -> Bool {
        guard let lhsDate = lhs.dateUpdatedAsDate, let rhsDate = rhs.dateUpdatedAsDate else { return false }
        return lhsDate > rhsDate
    }
}
