//
//  Connection+CloudCalls.swift
//  Benji
//
//  Created by Benji Dodgson on 2/11/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures
import PhoneNumberKit

struct UpdateConnection: CloudFunction {
    typealias ReturnType = Void

    var connection: Connection
    var status: Connection.Status

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<Void> {
        let params = ["connectionId": self.connection.objectId!,
                      "status": self.status.rawValue]

        return self.makeRequest(andUpdate: statusables,
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

    func makeRequest(andUpdate statusables: [Statusable], viewsToIgnore: [UIView]) -> Future<[Connection]> {

        let promise = Promise<ReturnType>()

        // Trigger the loading event for all statusables
        for statusable in statusables {
            statusable.handleEvent(status: .loading)
        }

        // Reference the statusables weakly in case they are deallocated before the signal finishes.
        let weakStatusables: [WeakAnyStatusable] = statusables.map { (statusable)  in
            return WeakAnyStatusable(statusable)
        }

        PFCloud.callFunction(inBackground: "getConnections",
                             withParameters: nil) { (object, error) in

            if let error = error {
                SessionManager.shared.handleParse(error: error)
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .error(error.localizedDescription))
                }
                promise.reject(with: error)
            } else if let dict = object as? [String: [Connection]] {
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .saved)
                }
                // A saved status is temporary so we set it to complete after a short delay
                delay(2.0) {
                    weakStatusables.forEach { (statusable) in
                        statusable.value?.handleEvent(status: .complete)
                    }

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
                    promise.resolve(with: all)
                }
            } else {
                weakStatusables.forEach { (statusable) in
                    statusable.value?.handleEvent(status: .error("Request failed"))
                }
                promise.reject(with: ClientError.apiError(detail: "Request failed"))
            }
        }

        return promise.ignoreUserInteractionEventsUntilDone(for: viewsToIgnore)
    }
}


