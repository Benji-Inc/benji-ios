//
//  MessageSequenceController.swift
//  Jibber
//
//  Created by Martin Young on 12/10/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol MessageSequenceController: DataController {

    var messageSequence: MessageSequence? { get }
    var hasLoadedAllPreviousMessages: Bool { get }
    var cid: ConversationID? { get }
    var messages: [Messageable] { get }
}
