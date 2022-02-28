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

    private var initializeTask: Task<Void, Never>?

    func initializeIfNeeded() async {
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            await initializeTask.value
            return
        }

        self.initializeTask = Task {
            do {
                self.connections
                = try await GetAllConnections().makeRequest(andUpdate: [],
                                                            viewsToIgnore: []).filter { (connection) -> Bool in
                    return !connection.nonMeUser.isNil
                }

                self.subscribeToUpdates()
            } catch {
                logError(error)
            }
        }

        await self.initializeTask?.value
    }

    private func subscribeToUpdates() {
        Client.shared.shouldPrintWebSocketLog = false

        self.queries.forEach { query in
            let subscription = Client.shared.subscribe(query)

            subscription.handleEvent { query, event in
                switch event {
                case .deleted, .entered, .left, .created:
                    break
                case .updated(let object):
                    guard let connection = object as? Connection else { break }
                    self.connectionUpdated = connection
                }
            }
        }
    }
}
