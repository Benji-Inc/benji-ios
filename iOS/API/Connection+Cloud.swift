//
//  Connection+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

struct CreateConnection: CloudFunction {
    typealias ReturnType = Any

    var to: User

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        let params = ["to": self.to.objectId!,
                      "status": Connection.Status.invited.rawValue]

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "createConnection",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}

struct UpdateConnection: CloudFunction {
    typealias ReturnType = Any

    var connection: Connection
    var status: Connection.Status

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        let params = ["connectionId": self.connection.objectId!,
                      "status": self.status.rawValue]

        return self.makeRequest(andUpdate: statusables,
                                params: params,
                                callName: "updateConnection",
                                viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }
}

struct GetAllConnections: CloudFunction {
    typealias ReturnType = [Connection]

    enum Direction: String {
        case incoming
        case outgoing
        case all
    }

    var direction: Direction = .all

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<[Connection], Error> {

        return self.makeRequest(andUpdate: statusables,
                                params: [:],
                                callName: "getConnections",
                                viewsToIgnore: viewsToIgnore).map { (value) -> [Connection] in
                                    if let dict = value as? [String: [Connection]] {
                                        var all: [Connection] = []

                                        switch self.direction {
                                        case .incoming:
                                            if let incoming = dict["incoming"] {
                                                all = incoming
                                            }
                                        case .outgoing:
                                            if let outgoing = dict["outgoing"] {
                                                all = outgoing
                                            }
                                        case .all:
                                            if let incoming = dict["incoming"] {
                                                all.append(contentsOf: incoming)
                                            }
                                            if let outgoing = dict["outgoing"] {
                                                all.append(contentsOf: outgoing)
                                            }
                                        }

                                        return all
                                    } else {
                                        return []
                                    }
                                }.eraseToAnyPublisher()
    }
}


