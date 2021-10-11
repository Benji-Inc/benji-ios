//
//  ChatChannelMessage+Messageable.swift
//  ChatChannelMessage+Messageable
//
//  Created by Martin Young on 9/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

typealias Message = ChatMessage

extension ChatMessage: Messageable {

    var isFromCurrentUser: Bool {
        return self.isSentByCurrentUser
    }

    var authorID: String {
        return self.author.id
    }

    var attributes: [String : Any]? {
        return nil
    }

    var avatar: Avatar {
        return self.author
    }

    var status: MessageStatus {
        return .sent
    }

    var context: MessageContext {
        return .passive
    }

    var hasBeenConsumedBy: [String] {
        return []
    }

    var kind: MessageKind {
        return .text(self.text)
    }

    func updateConsumers(with consumer: Avatar) async throws -> Messageable {
        return self
    }
}
