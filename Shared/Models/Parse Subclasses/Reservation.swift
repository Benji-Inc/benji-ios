//
//  Reservation.swift
//  Benji
//
//  Created by Benji Dodgson on 5/9/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import LinkPresentation

enum ReservationKey: String {
    case user
    case createdBy
    case isClaimed
    case reservationId
    case contactId
}

final class Reservation: PFObject, PFSubclassing {

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var isClaimed: Bool {
        return self.getObject(for: .isClaimed) ?? false
    }

    var user: User? {
        return self.getObject(for: .user)
    }

    var createdBy: User? {
        return self.getObject(for: .createdBy)
    }

    var contactId: String? {
        get {
            return self.getObject(for: .contactId)
        }
        set {
            self.setObject(for: .contactId, with: newValue)
        }
    }

    static func getReservations(for user: User) -> Future<[Reservation], Error> {
        return Future { promise in
            if let query = Reservation.query() {
                query.whereKey(ReservationKey.createdBy.rawValue, equalTo: user)
                query.findObjectsInBackground { (objects, error) in
                    if let reservations = objects as? [Reservation] {
                        promise(.success(reservations))
                    } else if let e = error {
                        promise(.failure(e))
                    } else {
                        promise(.failure(ClientError.generic))
                    }
                }
            } else {
                promise(.failure(ClientError.generic))
            }
        }
    }

    static func getFirstUnclaimed(for user: User) -> Future<Reservation, Error> {
        return Future { promise in
            if let query = Reservation.query() {
                query.whereKey(ReservationKey.createdBy.rawValue, equalTo: user)
                query.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
                query.findObjectsInBackground { (objects, error) in
                    if let reservations = objects as? [Reservation], let first = reservations.first {
                        promise(.success(first))
                    } else if let e = error {
                        promise(.failure(e))
                    } else {
                        promise(.failure(ClientError.generic))
                    }
                }
            } else {
                promise(.failure(ClientError.generic))
            }
        }
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

private var reservationMetadataKey: UInt8 = 0
private var linkKey: UInt8 = 0
extension Reservation: UIActivityItemSource, StatusableRequest {
    typealias ReturnType = Void

    private(set) var metadata: LPLinkMetadata? {
        get {
            return self.getAssociatedObject(&reservationMetadataKey)
        }
        set {
            self.setAssociatedObject(key: &reservationMetadataKey, value: newValue)
        }
    }

    private(set) var link: String? {
        get {
            return self.getAssociatedObject(&linkKey)
        }
        set {
            self.setAssociatedObject(key: &linkKey, value: newValue)
        }
    }

    var message: String? {
        guard let link = self.link else { return nil }
        return "Claim your RSVP by tapping 👇\n\(link)"
    }

    func prepareMetaData(andUpdate statusables: [Statusable]) -> Future<Void, Error> {
        return Future { promise in
            let metadataProvider = LPMetadataProvider()

            // Trigger the loading event for all statusables
            for statusable in statusables {
                statusable.handleEvent(status: .loading)
            }

            let domainURL = "https://ourown.chat"
            if let objectId = self.objectId {
                self.link = domainURL + "/reservation?reservationId=\(objectId)"
            }
            if let url = URL(string: domainURL) {
                metadataProvider.startFetchingMetadata(for: url) { [unowned self] (metadata, error) in
                    runMain {
                        if let e = error {
                            for statusable in statusables {
                                statusable.handleEvent(status: .error("Error"))
                            }
                            promise(.failure(e))
                        } else {
                            self.metadata = metadata
                            for statusable in statusables {
                                statusable.handleEvent(status: .complete)
                            }
                            promise(.success(()))
                        }
                    }
                }
            } else {
                promise(.failure(ClientError.generic))
            }
        }
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return URL(string: self.link!)!
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        guard let link = self.link else { return nil }
        return "Claim your reservation by tapping 👇\n\(link)"
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        return self.metadata
    }
}

