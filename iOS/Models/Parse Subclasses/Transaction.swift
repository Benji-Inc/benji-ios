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
    case description
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
    
    var amount: Int {
        get { self.getObject(for: .amount) ?? 0 }
    }
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
