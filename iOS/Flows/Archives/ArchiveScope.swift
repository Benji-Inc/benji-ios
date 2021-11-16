//
//  ArchiveScope.swift
//  Jibber
//
//  Created by Benji Dodgson on 9/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TMROLocalization
import StreamChat

enum ArchiveScope: Int, CaseIterable {
    case recents
    case dms
    case groups

    var title: Localized {
        switch self {
        case .recents:
            return "Recents"
        case .dms:
            return "DMs"
        case .groups:
            return "Groups"
        }
    }

    var query: ChannelListQuery? {
        guard let userId = User.current()?.objectId else { return nil }

        switch self {
        case .recents:
            return ChannelListQuery(filter: .containMembers(userIds: [userId]),
                                    sort: [.init(key: .lastMessageAt, isAscending: false)],
                                    pageSize: 20)
        case .dms:
            return ChannelListQuery(filter: .and([.containMembers(userIds: [userId]), .lessOrEqual(.memberCount, than: 2)]),
                                    sort: [.init(key: .lastMessageAt, isAscending: false)],
                                    pageSize: 20)
        case .groups:
            return ChannelListQuery(filter: .and([.containMembers(userIds: [userId]), .greaterOrEqual(.memberCount, than: 3)]),
                                    sort: [.init(key: .lastMessageAt, isAscending: false)],
                                    pageSize: 20)
        }
    }
}
