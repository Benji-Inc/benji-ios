//
//  UserStore.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseSwift

class UserStore {

    static let shared = UserStore()
    private var cancellables = Set<AnyCancellable>()

    @Published var userUpdated: User?
    @Published var userDeleted: User?

    private(set) var users: [User] = []

//    private var queries: [PFQuery<PFObject>] {
//        return self.users.compactMap { user in
//            if let query = User.query(), let objectId = user.objectId {
//                query.whereKey("objectId", equalTo: objectId)
//                return query
//            }
//
//            return nil
//        }
//    }

    init() {
        self.initialize()
    }

    private func initialize() {
        ConnectionStore.shared.$isReady.mainSink { isReady in
            if isReady {
                onceEver(token: "userStoreSubscribe") {
                    Task {
                        await self.subscribeToUpdates()
                    }
                }
            }
        }.store(in: &self.cancellables)
    }

    private func subscribeToUpdates() async {

        var unfetchedUserIds = ConnectionStore.shared.connections.compactMap { connection in
            return connection.nonMeUser?.objectId
        }

        if let current = User.current?.objectId {
            unfetchedUserIds.append(current)
        }

//        if let users = try? await User.fetchAndUpdateLocalContainer(where: unfetchedUserIds,
//                                                                         container: .users) {
//            self.users = users
//        }
//
//        self.users.forEach { user in
//            self.userUpdated = user 
//        }
//
//        self.queries.forEach { query in
//
//            let subscription = Client.shared.subscribe(query)
//
//            subscription.handleEvent { query, event in
//                switch event {
//                case .deleted(let object):
//                    if let user = object as? User {
//                        self.userDeleted = user
//                    }
//                case .entered(_):
//                    break
//                case .left(_):
//                    break
//                case .created(_):
//                    break
//                case .updated(let object):
//                    if let user = object as? User {
//                        self.userUpdated = user
//                    }
//                }
//            }
//        }
    }
}
