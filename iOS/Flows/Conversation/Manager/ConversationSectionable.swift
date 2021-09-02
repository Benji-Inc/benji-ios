//
//  ConversationSectionable.swift
//  Benji
//
//  Created by Benji Dodgson on 11/9/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import TwilioChatClient

class ConversationSectionable {

    var date: Date
    var items: [Messageable] = []
    var conversationType: ConversationType?

    var firstMessageIndex: Int? {
        guard let message = self.items.first as? TCHMessage else { return nil }
        return message.index?.intValue
    }

    init(date: Date,
         items: [Messageable],
         conversationType: ConversationType? = nil) {

        self.date = date
        self.items = items
        self.conversationType = conversationType
    }
}
