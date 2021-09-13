//
//  ConversationSectionable.swift
//  Benji
//
//  Created by Benji Dodgson on 11/9/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

class ConversationSectionable {

    var date: Date
    var items: [Messageable] = []
    var conversationType: ConversationType?

    var firstMessageIndex: Int? {
        #warning("Implement or delete")
        return nil
    }

    init(date: Date,
         items: [Messageable],
         conversationType: ConversationType? = nil) {

        self.date = date
        self.items = items
        self.conversationType = conversationType
    }
}
