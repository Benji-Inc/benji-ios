//
//  ConnectionStore.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import Combine

class ConnectionStore {

    static let shared = ConnectionStore()

    @Published var isReady: Bool = false
    @Published var connectionUpdated: Connection?

    private(set) var connections: [Connection] = []

    private var queries: [PFQuery<PFObject>] {
        return self.connections.compactMap { connection in
            if let query = Connection.query(), let objectId = connection.objectId {
                query.whereKey("objectId", equalTo: objectId)
                return query
            }

            return nil
        }
    }

    init() {
        Task {
            await self.getConnections()
        }
    }

    private func getConnections() async {

        do {
            self.connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []).filter { (connection) -> Bool in
                return !connection.nonMeUser.isNil
            }

            self.subscibeToUpdates()
        } catch {
            print(error)
        }
    }

    private func subscibeToUpdates() {
        self.isReady = true

        self.queries.forEach { query in

            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { query, event in
                switch event {
                case .deleted(_):
                    break
                case .entered(_):
                    break
                case .left(_):
                    break
                case .created(_):
                    break
                case .updated(let object):
                    if let connection = object as? Connection {
                        self.connectionUpdated = connection
                    }
                }
            }
        }
    }
}
