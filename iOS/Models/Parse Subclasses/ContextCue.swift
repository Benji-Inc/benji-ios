//
//  ContextCue.swift
//  Jibber
//
//  Created by Benji Dodgson on 3/6/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum ContextCueKey: String {
    case owner
    case emojis
    case message
    case attributes
}

final class ContextCue: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }
    
    var owner: User? {
        get { self.getObject(for: .owner) }
        set { self.setObject(for: .owner, with: newValue) }
    }
    
    var emojis: [String] {
        get { self.getObject(for: .emojis) ?? [] }
        set { self.setObject(for: .emojis, with: newValue)}
    }
    
    var message: String? {
        get { self.getObject(for: .message) }
        set { self.setObject(for: .message, with: newValue) }
    }
    
    var attributes: [String: AnyHashable]? {
        get { self.getObject(for: .attributes) }
        set { self.setObject(for: .attributes, with: newValue) }
    }
    
//    static func fetchAllCurrentTransactions() async throws -> [Transaction] {
//        let objects: [Transaction] = try await withCheckedThrowingContinuation { continuation in
//            guard let query = self.query() else {
//                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
//                return
//            }
//            query.whereKey("to", equalTo: User.current()!)
//            query.findObjectsInBackground { objects, error in
//                if let objs = objects as? [Transaction] {
//                    continuation.resume(returning: objs)
//                } else if let e = error {
//                    continuation.resume(throwing: e)
//                } else {
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//
//        return objects
//    }
    
//    static func fetchAllConnectionsTransactions() async throws -> [Transaction] {
//        guard let connections = try? await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []) else { return [] }
//
//        let connectionIds: [String] = connections.filter({ connection in
//            return connection.status == .accepted
//        }).compactMap({ connection in
//            return connection.nonMeUser?.objectId
//        })
//
//        let objects: [Transaction] = try await withCheckedThrowingContinuation { continuation in
//
//            guard let query = self.query() else {
//                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
//                return
//            }
//            query.whereKey("to", containedIn: connectionIds)
//            query.findObjectsInBackground { objects, error in
//                if let objs = objects as? [Transaction] {
//                    continuation.resume(returning: objs)
//                } else if let e = error {
//                    continuation.resume(throwing: e)
//                } else {
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//
//        return objects
//    }
    
//    static func createIfNeeded(for type: EventType) async throws {
//
//        if type.isUnique {
//            _ = try await Transaction.getFirstObject(where: TransactionKey.eventType.rawValue,
//                                                                         contains: type.rawValue,
//                                                                         forUserId: User.current()?.objectId)
//            try await createTransaction()
//        } else {
//            try await createTransaction()
//        }
//
//        func createTransaction() async throws {
//            let transaction = Transaction()
//            transaction.eventType = type
//            transaction.to = User.current()
//            transaction.from = User.current()
//            transaction.amount = type.amount
//            transaction.note = type.note
//            try await transaction.saveToServer()
//
//            await ToastScheduler.shared.schedule(toastType: .transaction(transaction))
//        }
//    }
}

extension ContextCue: Objectable {
    typealias KeyType = ContextCueKey

    func getObject<Type>(for key: ContextCueKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: ContextCueKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: ContextCueKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
