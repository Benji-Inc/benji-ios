//
//  File.swift
//  Jibber
//
//  Created by Benji Dodgson on 6/18/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseLiveQuery
import Parse
import Combine

class ConnectionsManager {

    static let shared = ConnectionsManager()

    @Published var userUpdated: User?

    private(set) var connectedUsers: [User] = []
    private var userQueries: [PFQuery<PFObject>] = []

    init() {
        Task {
            await self.subscribeToUpdates()
        }
    }

    private func subscribeToUpdates() async {
        do {
            let connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: [])
            self.connectedUsers = connections.filter({ connection in
                return connection.status == .accepted
            }).compactMap({ connection in
                return connection.nonMeUser
            })
            self.subscribeToUserUpdates()
        } catch {
            print(error)
        }
    }

    private func subscribeToUserUpdates() {
        self.userQueries.removeAll()

        self.connectedUsers.forEach { user in
            if let query = User.query() {

                query.whereKey("objectId", equalTo: user.objectId!)

                self.userQueries.append(query)
                let subscription = Client.shared.subscribe(query)

                subscription.handleEvent { query, event in
                    switch event {
                    case .updated(let obj):
                        guard let user = obj as? User else { return }
                        self.userUpdated = user
                    default:
                        break
                    }
                }
            }
        }
    }
}
