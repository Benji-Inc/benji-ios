//
//  Transaction.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum TransactionKey: String {
    case to
    case from
    case note
    case amount
    case eventType
}

final class Transaction: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }
    
    enum EventType: String {
        case newUser = "NEW_USER"
        case swipeToSend = "SWIPE_TO_SEND"
        case invite = "INVITE"
        case bugReport = "BUG_REPORT"
        
        var isUnique: Bool {
            switch self {
            case .newUser:
                return true
            case .swipeToSend:
                return true
            case .invite:
                return false
            case .bugReport:
                return false
            }
        }
        
        var amount: Double {
            switch self {
            case .newUser:
                return 10.0
            case .swipeToSend:
                return 1.0
            case .invite:
                return 5.0
            case .bugReport:
                return 2.0
            }
        }
        
        var note: String {
            switch self {
            case .newUser:
                return "For joining Jibber, and just being awesome. 🥳"
            case .swipeToSend:
                return "For swiping like a pro. 😎"
            case .invite:
                return "For being a team player. 🤝"
            case .bugReport:
                return "For hepling us find 🕵️‍♀️ and smash those 🐛."
            }
        }
    }
    
    var to: User? {
        get { self.getObject(for: .to) }
        set { self.setObject(for: .to, with: newValue) }
    }
    
    var from: User? {
        get { self.getObject(for: .from) }
        set { self.setObject(for: .from, with: newValue)}
    }
    
    var amount: Double {
        get { self.getObject(for: .amount) ?? 0 }
        set { self.setObject(for: .amount, with: newValue) }
    }
    
    var note: String {
        get { self.getObject(for: .note) ?? "" }
        set { self.setObject(for: .note, with: newValue) }
    }
    
    var eventType: EventType? {
        get {
            guard let string: String = self.getObject(for: .eventType),
                    let type = EventType.init(rawValue: string) else {
                return nil
            }

            return type
        }
        
        set {
            self.setObject(for: .eventType, with: newValue?.rawValue)
        }
    }
    
    static func fetchAllCurrentTransactions() async throws -> [Transaction] {
        let objects: [Transaction] = try await withCheckedThrowingContinuation { continuation in
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
                return
            }
            query.whereKey("to", equalTo: User.current()!)
            query.findObjectsInBackground { objects, error in
                if let objs = objects as? [Transaction] {
                    continuation.resume(returning: objs)
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }

        return objects
    }
    
    static func fetchAllConnectionsTransactions() async throws -> [Transaction] {
        guard let connections = try? await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: []) else { return [] }
        
        let connectionIds: [String] = connections.filter({ connection in
            return connection.status == .accepted
        }).compactMap({ connection in
            return connection.nonMeUser?.userObjectId
        })
        
        let objects: [Transaction] = try await withCheckedThrowingContinuation { continuation in
            
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
                return
            }
            query.whereKey("to", containedIn: connectionIds)
            query.findObjectsInBackground { objects, error in
                if let objs = objects as? [Transaction] {
                    continuation.resume(returning: objs)
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }

        return objects
    }
    
    static func createIfNeeded(for type: EventType) async throws {
        
        if type.isUnique {
            _ = try await Transaction.getFirstObject(where: TransactionKey.eventType.rawValue,
                                                                         contains: type.rawValue,
                                                                         forUserId: User.current()?.objectId)
            try await createTransaction()
        } else {
            try await createTransaction()
        }
        
        func createTransaction() async throws {
            let transaction = Transaction()
            transaction.eventType = type
            transaction.to = User.current()
            transaction.from = User.current()
            transaction.amount = type.amount
            transaction.note = type.note
            try await transaction.saveToServer()
            
            await ToastScheduler.shared.schedule(toastType: .transaction(transaction))
        }
    }
}

extension Transaction: Objectable {
    typealias KeyType = TransactionKey

    func getObject<Type>(for key: TransactionKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: TransactionKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: TransactionKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
