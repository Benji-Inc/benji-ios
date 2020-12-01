//
//  DisplayableChannel.swift
//  Benji
//
//  Created by Benji Dodgson on 10/6/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension Range: Comparable {
    public static func < (lhs: Range<Bound>, rhs: Range<Bound>) -> Bool {
        return lhs.lowerBound < rhs.lowerBound
    }
}

class DisplayableChannel: ManageableCellItem, Hashable, Comparable {

    var channelType: ChannelType

    var headerModel: ChannelHeaderModel {
        return ChannelHeaderModel(title: Lorem.randomString(),
                                  subtitle: Lorem.randomString())
    }

    init(channelType: ChannelType) {
        self.channelType = channelType
    }

    var id: String {
        self.channelType.id
    }

    var isFromCurrentUser: Bool {
        return self.channelType.isFromCurrentUser
    }

    func diffIdentifier() -> NSObjectProtocol {
        return self.channelType.diffIdentifier()
    }

    static func == (lhs: DisplayableChannel, rhs: DisplayableChannel) -> Bool {
        return lhs.channelType.uniqueName == rhs.channelType.uniqueName 
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.channelType.uniqueName)
    }

    static func < (lhs: DisplayableChannel, rhs: DisplayableChannel) -> Bool {
        return lhs.channelType.dateUpdated < rhs.channelType.dateUpdated
    }
}
