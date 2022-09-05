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
        let userIds = members.map { member in
            return member.id
        }
        return .containsOnly(userIds: userIds)
    }

    /// Filter to match conversations that contain all and only members with the passed in user ids.
    static func containsOnly(userIds: [UserId]) -> Filter<Scope> {
        var memberFilters: [Filter<Scope>] = []
        for userID in userIds {
            memberFilters.append(.containMembers(userIds: [userID]))
        }

        // Make there aren't other members in this channel who weren't included in the list.
        let memberCountFilter: Filter<Scope> = .equal(.memberCount, to: userIds.count)
        memberFilters.append(memberCountFilter)

        return .and(memberFilters)
    }

    /// Filter to match conversations that contain all the passed in members. May contain other members.
    static func containsAtLeastTheseMembers(_ members: [ConversationMember]) -> Filter<Scope> {
        let userIds = members.map { member in
            return member.id
        }
        return .containsAtLeastThese(userIds: userIds)
    }

    /// Filter to match conversations that contain all the members with the passed in user ids. May contain other members.
    static func containsAtLeastThese(userIds: [UserId], type: ChannelType = .messaging) -> Filter<Scope> {
        var filters: [Filter<Scope>] = []
        for userID in userIds {
            filters.append(.containMembers(userIds: [userID]))
        }
        filters.append(.equal(.type, to: type))
        return .and(filters)
    }
    
    /// Filter to match conversations that match all the included cids.
    static func containsAtLeastThese(conversationIds: [ConversationId], type: ChannelType = .messaging) -> Filter<Scope> {
        var filters: [Filter<Scope>] = []
        for cid in conversationIds {
            filters.append(.equal(.cid, to: cid))
        }
        
        filters.append(.equal(.type, to: type))
        return .and(filters)
    }
}
