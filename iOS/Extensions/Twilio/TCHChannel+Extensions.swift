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
import Combine

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
#warning("Convert to async")
    func getNonMeMembers() -> Future<[TCHMember], Error> {
        return Future { promise in
            if let members = self.members?.membersList() {
                var nonMeMembers: [TCHMember] = []
                members.forEach { (member) in
                    if member.identity != User.current()?.objectId {
                        nonMeMembers.append(member)
                    }
                }
                promise(.success(nonMeMembers))
            } else {
                promise(.failure(ClientError.message(detail: "There was a problem fetching other members.")))
            }
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
              let text = attributes.dictionary?[ChannelKey.description.rawValue] as? String else { return String() }
        return text
    }
#warning("Convert to async")
    func join() -> Future<Void, Error> {
        return Future { promise in
            self.join { result in
                if result.isSuccessful() {
                    promise(.success(()))
                } else if let e = result.error {
                    promise(.failure(e))
                } else {
                    promise(.failure(ClientError.apiError(detail: "Failed to join channel")))
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
