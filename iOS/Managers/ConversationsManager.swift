//
//  ConversationsManager.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import StreamChat

class ConversationsManager: EventsControllerDelegate {

    static let shared = ConversationsManager()

    private let controller = ChatClient.shared.eventsController()

    init() {
        self.initialize()
    }

    private func initialize() {
        self.controller.delegate = self
    }

    func eventsController(_ controller: EventsController, didReceiveEvent event: Event) {

        switch event {
        case let event as MessageNewEvent:
            Task {
                await ToastScheduler.shared.schedule(toastType: .newMessage(event.message))
            }
        case let event as ReactionNewEvent:
            Task {
                await ToastScheduler.shared.schedule(toastType: .newMessage(event.message))
            }
        default:
            break
        }
    }
}
