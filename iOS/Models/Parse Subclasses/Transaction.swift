//
//  Transaction.swift
//  Jibber
//
//  Created by Benji Dodgson on 2/4/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse

enum TrasactionKey: String {
    case to
    case from
    case note
    case amount
}

final class Transaction: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
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
    }
    
    var note: String {
        get { self.getObject(for: .note) ?? "" }
        set { self.setObject(for: .note, with: newValue) }
    }
    
//    static func fetchAllTransactions() async throws -> [Transaction] {
//        let objects: [Self] = try await withCheckedThrowingContinuation { continuation in
//            guard let query = self.query() else {
//                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
//                return
//            }
//            query.whereKey("to", equalTo: User.current()!)
//            query.findObjectsInBackground { objects, error in
//                if let objs = objects as? [Self] {
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
}

extension Transaction: Objectable {
    typealias KeyType = TrasactionKey

    func getObject<Type>(for key: TrasactionKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: TrasactionKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: TrasactionKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}
