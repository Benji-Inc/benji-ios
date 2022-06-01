//
//  ConversationsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

protocol ActiveConversationable {
    var activeConversation: Conversation? { get }
}

extension ActiveConversationable {
    var activeConversation: Conversation? {
        return ConversationsManager.shared.activeConversation
    }
}

struct ReactionEvent {
    enum EventType {
        case updated(Conversation)
        case new(Conversation)
        case deleted(Conversation)
    }
}

class ConversationsManager: EventsControllerDelegate {

    static let shared = ConversationsManager()

    private let controller = ConversationsClient.shared.eventsController

    @Published var activeController: MessageSequenceController? 
    @Published var activeConversation: Conversation?

    @Published var reactionEvent: Event?
    @Published var messageEvent: Event?
    @Published var conversationEvent: ChannelUpdatedEvent?

    init() {
        self.initialize()
    }

    private func initialize() {
        self.controller.delegate = self
    }

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {
        switch event {
        case let event as MessageNewEvent:

            if self.activeConversation.isNil {
                Task {
                    await ToastScheduler.shared.schedule(toastType: .newMessage(event.message))
                }
            } else if let last = self.activeConversation, event.channel != last {
                Task {
                    await ToastScheduler.shared.schedule(toastType: .newMessage(event.message))
                }
            }
            self.messageEvent = event

        case let event as ReactionNewEvent:
            self.reactionEvent = event
        case let event as ReactionDeletedEvent:
            self.reactionEvent = event
        case let event as ReactionUpdatedEvent:
            self.reactionEvent = event
        case let event as ChannelUpdatedEvent:
            self.conversationEvent = event 
        default:
            break
        }
    }
}
