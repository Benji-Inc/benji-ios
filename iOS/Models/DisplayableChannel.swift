//
//  DisplayableConversation.swift
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

class DisplayableConversation: Hashable, Comparable {

    var channelType: ConversationType

    init(channelType: ConversationType) {
        self.channelType = channelType
    }

    var id: String {
        self.channelType.id
    }

    var isFromCurrentUser: Bool {
        return self.channelType.isFromCurrentUser
    }

    static func == (lhs: DisplayableConversation, rhs: DisplayableConversation) -> Bool {
        return lhs.channelType.uniqueName == rhs.channelType.uniqueName 
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.channelType.uniqueName)
    }

    static func < (lhs: DisplayableConversation, rhs: DisplayableConversation) -> Bool {
        return lhs.channelType.dateUpdated < rhs.channelType.dateUpdated
    }
}
