//
//  Reservation.swift
//  Benji
//
//  Created by Benji Dodgson on 5/9/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

enum ReservationKey: String {
    case user
    case createdBy
    case code
    case position
    case isClaimed
}

final class Reservation: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var code: String {
        return self.getObject(for: .code) ?? String()
    }

    var isClaimed: Bool {
        return self.getObject(for: .isClaimed) ?? false
    }

    var position: Int? {
        return self.getObject(for: .position)
    }

    var user: User? {
        return self.getObject(for: .user)
    }

    var createdBy: User? {
        return self.getObject(for: .createdBy)
    }
}

extension Reservation: Objectable {
    typealias KeyType = ReservationKey

    func getObject<Type>(for key: ReservationKey) -> Type? {
        return self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: ReservationKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: ReservationKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

extension Reservation: ManageableCellItem {
    var id: String {
        return self.objectId!
    }
}

