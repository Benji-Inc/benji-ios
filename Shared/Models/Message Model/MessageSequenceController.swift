//
//  MessageSequenceController.swift
//  Jibber
//
//  Created by Martin Young on 4/14/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation

protocol MessageSequenceController {

    var streamCid: ConversationId? { get }
    var sequence: [Messageable] { get }
}

extension MessageSequenceController {

    func getMessage(withId id: String) -> Messageable? {
        return self.sequence.first { message in
            return message.id == id
        }
    }
}

/// An object representing a controller for a null message sequence. It will have no cid and an empty array of messages.
struct EmptyMessageSequenceController: MessageSequenceController {
    var streamCid: ConversationId? = nil
    var sequence: [Messageable] = []
}
