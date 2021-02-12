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

    func getAuthorAsUser() -> Future<User, Error> {
        return User.localThenNetworkQuery(for: self.createdBy!)
    }

    func getUsers(excludeMe: Bool = false) -> Future<[User], Error> {

        let members = self.members!.membersList()

        var identifiers: [String] = []
        members.forEach { (member) in
            if let identifier = member.identity {
                if identifier == User.current()?.objectId, excludeMe {
                } else {
                    identifiers.append(identifier)
                }
            }
        }

        return User.localThenNetworkArrayQuery(where: identifiers,
                                               isEqual: true,
                                               container: .channel(identifier: self.sid!))
    }

    var channelDescription: String {
        guard let attributes = self.attributes(),
              let text = attributes.dictionary?[ChannelKey.description.rawValue] as? String else { return String() }
        return text
    }

    func getUnconsumedAmount() -> Future<FeedType, Error> {
        return Future { promise in
            var totalUnread: Int = 0
            if let messagesObject = self.messages {
                self.getMessagesCount { (result, count) in
                    if result.isSuccessful() {
                        messagesObject.getLastWithCount(count) { (messageResult, messages) in
                            if messageResult.isSuccessful(), let msgs = messages {
                                msgs.forEach { (message) in
                                    if !message.isFromCurrentUser, !message.isConsumed, message.canBeConsumed {
                                        totalUnread += 1
                                    }
                                }
                                promise(.success(.unreadMessages(self, totalUnread)))
                            } else {
                                promise(.failure(ClientError.message(detail: "Unable to get messages.")))
                            }
                        }
                    } else {
                        promise(.failure(ClientError.message(detail: "Failed to get message count.")))
                    }
                }
            } else {
                promise(.failure(ClientError.message(detail: "There were no messages.")))
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
