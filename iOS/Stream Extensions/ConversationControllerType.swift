//
//  ConversationControllerType.swift
//  ConversationControllerType
//
//  Created by Martin Young on 10/19/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

/// A common protocol to handle differnt conversation controller types. This allows you to interface with
/// message threads (MessageController) and conversations (ConversationController) in a unified way.
protocol ConversationControllerType {
    /// The conversation related to this controller.
    var conversation: Conversation? { get }
    /// The original message if this is controller for message  thread.
    var rootMessage: Message? { get }
    /// The messages currenlty loaded on this controller. In a thread, these would be reply messages.
    var messages: LazyCachedMapCollection<ChatMessage> { get }
    /// True if all messages (or replies) have been loaded.
    var hasLoadedAllPreviousMessages: Bool { get }
}

extension ConversationControllerType {

    var isThread: Bool {
        return self.rootMessage.exists
    }

    var cid: ConversationId? {
        return self.conversation?.cid
    }

    var rootMessageID: MessageId? {
        return self.rootMessage?.id
    }
}

extension ConversationController: ConversationControllerType {

    var rootMessage: Message? {
        return nil
    }
}

extension MessageController: ConversationControllerType {

    var rootMessage: Message? {
        return self.message
    }

    var messages: LazyCachedMapCollection<ChatMessage> {
        return self.replies
    }

    var conversation: Conversation? {
        return ConversationController.controller(for: self.cid.description).conversation
    }
    
    var hasLoadedAllPreviousMessages: Bool {
        return self.hasLoadedAllPreviousReplies
    }
}
