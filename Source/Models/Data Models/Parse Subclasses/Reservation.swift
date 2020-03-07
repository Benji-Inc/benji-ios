//
//  Reservation.swift
//  Benji
//
//  Created by Benji Dodgson on 11/2/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import TMROFutures

enum ReservationKeys: String {
    case position
    case code
    case isClaimed
    case user
    case link
}

final class Reservation: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    private(set) var position: Double? {
        get { return self.getObject(for: .position) }
        set { self.setObject(for: .position, with: newValue) }
    }

    private(set) var code: String {
        get { return self.getObject(for: .code) ?? String() }
        set { self.setObject(for: .code, with: newValue) }
    }

    private(set) var isClaimed: Bool {
        get { return self.getObject(for: .isClaimed) ?? false }
        set { self.setObject(for: .isClaimed, with: newValue) }
    }

    private(set) var link: String {
        get { return self.getObject(for: .link) ?? String() }
        set { self.setObject(for: .link, with: newValue) }
    }

    var user: User? {
        get { return self.getObject(for: .user) }
        set { self.setObject(for: .user, with: newValue) }
    }
}

extension Reservation: Objectable {
    typealias KeyType = ReservationKeys

    func getObject<Type>(for key: ReservationKeys) -> Type? {
        self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: ReservationKeys, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: ReservationKeys) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    func rounded(by value: Int) -> Double {
        return (self * Double(value)).rounded() / Double(value)
    }
}
