//
//  Reservation.swift
//  Benji
//
//  Created by Benji Dodgson on 5/9/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import ParseSwift
import Combine
import LinkPresentation

enum ReservationKey: String {
    case user
    case createdBy
    case isClaimed
    case contactId
    case conversationId
}

struct Reservation: ParseObject, ParseObjectMutable {
    
    //: These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    var isClaimed: Bool = false 
    var user: User?
    var createdBy: User?
    var conversationId: String?
    var contactId: String?
    
//    static func getUnclaimedReservationCount(for user: User) async -> Int {
//        return await withCheckedContinuation { continuation in
//            //            if let query = Reservation.query() {
//            //                query.whereKey(ReservationKey.createdBy.rawValue, equalTo: user)
//            //                query.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
//            //                query.countObjectsInBackground { count, error in
//            //                    if let _ = error {
//            //                        continuation.resume(returning: 0)
//            //                    } else {
//            //                        continuation.resume(returning: Int(count))
//            //                    }
//            //                }
//            //            } else {
//            //                continuation.resume(returning: 0)
//            //            }
//        }
//    }
}

private var reservationMetadataKey: UInt8 = 0
private var linkKey: UInt8 = 0
//extension Reservation: UIActivityItemSource {
//
//    private(set) var metadata: LPLinkMetadata? {
//        get {
//            return self.getAssociatedObject(&reservationMetadataKey)
//        }
//        set {
//            self.setAssociatedObject(key: &reservationMetadataKey, value: newValue)
//        }
//    }
//
//    private(set) var link: String? {
//        get {
//            return self.getAssociatedObject(&linkKey)
//        }
//        set {
//            self.setAssociatedObject(key: &linkKey, value: newValue)
//        }
//    }
//
//    var message: String? {
//        guard let link = self.link else { return nil }
//        return "RSVP code: \(String(optional: self.objectId))\nClaim your RSVP by tapping 👇\n\(link)"
//    }
//
//    var reminderMessage: String? {
//        guard let link = self.link else { return nil }
//        return "RSVP code: \(String(optional: self.objectId))\nJibber is an exclusive place to be social. I saved you a spot. Tap👇\n\(link)"
//    }
//
//    func prepareMetadata(andUpdate statusables: [Statusable]) async throws {
//        // Trigger the loading event for all statusables
//        await withTaskGroup(of: Void.self) { group in
//            for statusable in statusables {
//                group.addTask {
//                    await statusable.handleEvent(status: .loading)
//                }
//            }
//        }
//
//        do {
//            let _: Void = try await withCheckedThrowingContinuation { continuation in
//                let metadataProvider = LPMetadataProvider()
//
//                let domainURL = "https://joinjibber.com"
//                if let objectId = self.objectId {
//                    self.link = domainURL + "/reservation?reservationId=\(objectId)"
//                }
//
//                if let url = URL(string: domainURL) {
//                    metadataProvider.startFetchingMetadata(for: url) { [unowned self] (metadata, error) in
//                        Task.onMainActor {
//                            if let e = error {
//
//                                continuation.resume(throwing: e)
//                            } else {
//                                self.metadata = metadata
//
//                                continuation.resume(returning: ())
//                            }
//                        }
//                    }
//                } else {
//                    continuation.resume(throwing: ClientError.generic)
//                }
//            }
//
//            await withTaskGroup(of: Void.self) { group in
//                for statusable in statusables {
//                    group.addTask {
//                        await statusable.handleEvent(status: .complete)
//                    }
//                }
//            }
//        } catch {
//            await withTaskGroup(of: Void.self) { group in
//                for statusable in statusables {
//                    group.addTask {
//                        await statusable.handleEvent(status: .error(error.localizedDescription))
//                    }
//                }
//            }
//            throw error
//        }
//    }
//
//    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
//        return URL(string: self.link!)!
//    }
//
//    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
//        guard let link = self.link else { return nil }
//        return "Claim your reservation by tapping 👇\n\(link)"
//    }
//
//    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
//        return self.metadata
//    }
//
//    static func getAllUnclaimed() async -> [Reservation] {
//        let query = Reservation.query()
//        query?.whereKey(ReservationKey.createdBy.rawValue, equalTo: User.current()!)
//        query?.whereKey(ReservationKey.isClaimed.rawValue, equalTo: false)
//        do {
//            let objects = try await query?.findObjectsInBackground()
//            if let reservations = objects as? [Reservation] {
//                return reservations
//            } else {
//                return []
//            }
//        } catch {
//            logDebug(error)
//            return []
//        }
//    }
//}
//
