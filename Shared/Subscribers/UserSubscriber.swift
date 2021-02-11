//
//  UserManager.swift
//  Ours
//
//  Created by Benji Dodgson on 2/11/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery
import Parse

class UserSubscriber {

    struct Update {
        var user: User
        var status: Status

        enum Status {
            // The object has been updated, and is now included in the query
            case entered
            // The object has been updated, and is no longer included in the query
            case left
            // The object has been created, and is a part of the query
            case created
            // The object has been updated, and is still a part of the query
            case updated
            // The object has been deleted, and is no longer included in the query
            case deleted
        }
    }
    
    static let shared = UserSubscriber()

    @Published var update: Update?

    private(set) var subscription: Subscription<User>?

    init() {
        self.addSubscriber()
        Client.shared.shouldPrintWebSocketTrace = true
    }

    private func addSubscriber() {
        let query: PFQuery<User>  = PFQuery.init(className: "User")
        query.whereKey("objectId", equalTo: User.current()!.objectId!)
        self.subscription = Client.shared.subscribe(query)
        self.handleEvents()
    }

    private func handleEvents() {
        guard let subscription = self.subscription else { return }

        subscription.handleEvent { (query, event) in
            switch event {
            case .entered(let user):
                self.update = Update(user: user, status: .entered)
            case .left(let user):
                self.update = Update(user: user, status: .left)
            case .created(let user):
                self.update = Update(user: user, status: .created)
            case .updated(let user):
                self.update = Update(user: user, status: .updated)
            case .deleted(let user):
                self.update = Update(user: user, status: .deleted)
            }
        }
    }
}
