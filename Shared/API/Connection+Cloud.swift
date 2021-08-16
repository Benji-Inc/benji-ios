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

    func makeSynchronousRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {
        let params = ["to": self.to.objectId!,
                      "status": Connection.Status.invited.rawValue]

        return self.makeSynchronousRequest(andUpdate: statusables,
                                           params: params,
                                           callName: "createConnection",
                                           viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }

    func makeRequest(andUpdate statusables: [Statusable],
                     viewsToIgnore: [UIView]) async throws -> Any {

        let params = ["to": self.to.objectId!,
                      "status": Connection.Status.invited.rawValue]

        let result = try await self.makeRequest(andUpdate: statusables,
                                                params: params,
                                                callName: "createConnection",
                                                viewsToIgnore: viewsToIgnore)

        return result
    }
}

struct UpdateConnection: CloudFunction {
    typealias ReturnType = Any

    var connectionId: String
    var status: Connection.Status

    func makeSynchronousRequest(andUpdate statusables: [Statusable],
                                viewsToIgnore: [UIView]) -> AnyPublisher<Any, Error> {

        let params = ["connectionId": self.connectionId,
                      "status": self.status.rawValue]

        return self.makeSynchronousRequest(andUpdate: statusables,
                                           params: params,
                                           callName: "updateConnection",
                                           viewsToIgnore: viewsToIgnore).eraseToAnyPublisher()
    }

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) async throws -> Any {
        let params = ["connectionId": self.connectionId,
                      "status": self.status.rawValue]

        let result = try await self.makeRequest(andUpdate: statusables,
                                                params: params,
                                                callName: "updateConnection",
                                                viewsToIgnore: viewsToIgnore)
        return result
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

    func makeSynchronousRequest(andUpdate statusables: [Statusable],
                                viewsToIgnore: [UIView]) -> AnyPublisher<[Connection], Error> {

        return self.makeSynchronousRequest(andUpdate: statusables,
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

    func makeRequest(andUpdate statusables: [Statusable],
                     viewsToIgnore: [UIView]) async throws -> [Connection] {

        let result = try await self.makeRequest(andUpdate: statusables,
                                                params: [:],
                                                callName: "getConnections",
                                                viewsToIgnore: viewsToIgnore)

        if let dict = result as? [String: [Connection]] {
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
            throw ClientError.apiError(detail: "Get all connections error")
        }
    }
}
