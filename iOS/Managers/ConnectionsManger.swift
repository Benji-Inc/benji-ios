//
//  File.swift
//  Ours
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

    private(set) var connectedUsers: [User] = []

    @Published var userUpdated: User?

    private var cancellables = Set<AnyCancellable>()
    private var userQueries: [PFQuery<PFObject>] = []

    init() {
        self.subscribeToUpdates()
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    private func subscribeToUpdates() {

        GetAllConnections()
            .makeSynchronousRequest(andUpdate: [], viewsToIgnore: [])
            .mainSink { result in
                switch result {
                case .success(let connections):
                    self.connectedUsers = connections.filter({ connection in
                        return connection.status == .accepted
                    }).compactMap({ connection in
                        return connection.nonMeUser
                    })
                    self.subscribeToUserUdpates()
                case .error(_):
                    break
                }
            }.store(in: &self.cancellables)
    }

    private func subscribeToUserUdpates() {
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
