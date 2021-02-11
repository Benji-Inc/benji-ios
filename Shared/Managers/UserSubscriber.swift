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

    init() {
        self.addSubscriber()
    }

    private func addSubscriber() {
        if let query = User.query(), let currentId = User.current()?.objectId {
            query.whereKey("objectId", contains: currentId)
            self.handleEvents(for: Client.shared.subscribe(query))
        } else {
            fatalError()
        }
    }

    private func handleEvents(for subscription: Subscription<PFObject>) {

        subscription.handle(Event.entered) { [unowned self] (query, object) in
            guard let user = object as? User else { return }
            self.update = Update(user: user, status: .entered)
        }

        subscription.handle(Event.left) { [unowned self] (query, object) in
            guard let user = object as? User else { return }
            self.update = Update(user: user, status: .left)
        }

        subscription.handle(Event.created) { [unowned self] (query, object) in
            guard let user = object as? User else { return }
            self.update = Update(user: user, status: .created)
        }

        subscription.handle(Event.updated) { [unowned self] (query, object) in
            guard let user = object as? User else { return }
            self.update = Update(user: user, status: .updated)
        }

        subscription.handle(Event.deleted) { [unowned self] (query, object) in
            guard let user = object as? User else { return }
            self.update = Update(user: user, status: .deleted)
        }
    }
}
