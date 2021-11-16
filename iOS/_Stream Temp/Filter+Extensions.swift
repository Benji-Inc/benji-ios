//
//  Filter+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 11/16/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

extension Filter where Scope: AnyChannelListFilterScope {

    /// Filter to match conversations that contain all and only the passed in members.
    static func containOnlyMembers(_ members: [ConversationMember]) -> Filter<Scope> {
        var memberFilters: [Filter<Scope>] = []
        for userID in members.userIDs {
            memberFilters.append(.containMembers(userIds: [userID]))
        }

        // Make there aren't other members in this channel who weren't included in the list.
        let memberCountFilter: Filter<Scope> = .equal(.memberCount, to: members.count)
        memberFilters.append(memberCountFilter)

        return .and(memberFilters)
    }
}
