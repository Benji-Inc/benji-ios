//
//  DisplayableConversation.swift
//  Benji
//
//  Created by Benji Dodgson on 10/6/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class DisplayableConversation: Hashable, Comparable {

    var conversationType: ConversationType

    init(conversationType: ConversationType) {
        self.conversationType = conversationType
    }

    var id: String {
        self.conversationType.id
    }

    var isFromCurrentUser: Bool {
        return self.conversationType.isFromCurrentUser
    }

    static func == (lhs: DisplayableConversation, rhs: DisplayableConversation) -> Bool {
        return lhs.conversationType.id == rhs.conversationType.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.conversationType.id)
    }

    static func < (lhs: DisplayableConversation, rhs: DisplayableConversation) -> Bool {
        return lhs.conversationType.dateUpdated < rhs.conversationType.dateUpdated
    }
}
