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
import LinkPresentation

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
        return self.getObject(for: .code) ?? "123456"
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

    static func getReservations(for user: User) -> Future<[Reservation]> {
        let promise = Promise<[Reservation]>()
        if let query = Reservation.query() {
            query.whereKey(ReservationKey.createdBy.rawValue, equalTo: user)
            query.findObjectsInBackground { (objects, error) in
                if let reservations = objects as? [Reservation] {
                    promise.resolve(with: reservations)
                } else if let e = error {
                    promise.reject(with: e)
                } else {
                    promise.reject(with: ClientError.generic)
                }
            }
        } else {
            promise.reject(with: ClientError.generic)
        }
        
        return promise
    }

    static func getFirstUnclaimed(for user: User) -> Future<Reservation> {
        let promise = Promise<Reservation>()
        if let query = Reservation.query() {
            query.whereKey(ReservationKey.createdBy.rawValue, equalTo: user)
            query.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
            query.findObjectsInBackground { (objects, error) in
                if let reservations = objects as? [Reservation], let first = reservations.first {
                    promise.resolve(with: first)
                } else if let e = error {
                    promise.reject(with: e)
                } else {
                    promise.reject(with: ClientError.generic)
                }
            }
        } else {
            promise.reject(with: ClientError.generic)
        }

        return promise
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

private var reservationMetadataKey: UInt8 = 0
extension Reservation: UIActivityItemSource {

    private(set) var metadata: LPLinkMetadata? {
        get {
            return self.getAssociatedObject(&reservationMetadataKey)
        }
        set {
            self.setAssociatedObject(key: &reservationMetadataKey, value: newValue)
        }
    }

    func prepareMetaData() -> Future<Void> {
        let promise = Promise<Void>()
        let metadataProvider = LPMetadataProvider()
        if let url = URL(string: "https://testflight.apple.com/join/w3CExYsD") {
            metadataProvider.startFetchingMetadata(for: url) { (metadata, error) in
                if let e = error {
                    promise.reject(with: e)
                } else {
                    self.metadata = metadata
                    promise.resolve(with: ())
                }
            }
        } else {
            promise.reject(with: ClientError.generic)
        }

        return promise
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL(string: "https://testflight.apple.com/join/w3CExYsD")!
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return "Claim your reservation by entering: \(self.code) after tapping on this link: https://testflight.apple.com/join/w3CExYsD"
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        return self.metadata
    }
}

