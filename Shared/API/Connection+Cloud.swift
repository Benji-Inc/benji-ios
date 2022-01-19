//
//  Connection+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

struct CreateConnection: CloudFunction {

    typealias ReturnType = Any

    var to: User
    var reservation: Reservation?

    @discardableResult
    func makeRequest(andUpdate statusables: [Statusable],
                     viewsToIgnore: [UIView]) async throws -> Any {

        var params = ["to": self.to.objectId!,
                      "status": Connection.Status.invited.rawValue]
        
        if let rsvp = self.reservation?.objectId {
            params = ["reservationId": rsvp]
        }

        return try await self.makeRequest(andUpdate: statusables,
                                          params: params,
                                          callName: "createConnection",
                                          viewsToIgnore: viewsToIgnore)
    }
}

struct UpdateConnection: CloudFunction {
    typealias ReturnType = Any

    var connectionId: String
    var status: Connection.Status

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) async throws -> Any {
        let params = ["connectionId": self.connectionId,
                      "status": self.status.rawValue]

        return try await self.makeRequest(andUpdate: statusables,
                                          params: params,
                                          callName: "updateConnection",
                                          viewsToIgnore: viewsToIgnore)
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
