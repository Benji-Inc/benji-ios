//
//  NoticeSupplier.swift
//  Jibber
//
//  Created by Benji Dodgson on 5/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseLiveQuery
import Parse
import Localization

class NoticeSupplier {

    static let shared = NoticeSupplier()

    enum NoticeStatus {
        case deleted(SystemNotice)
        case updated(SystemNotice)
        case created(SystemNotice)
    }

    @Published private(set) var notices: [SystemNotice] = []
    @Published private(set) var noticeStatus: NoticeStatus? = nil

    func loadNotices() async {
//        do {
            self.notices = await self.getLocalNotices().sorted()
//            let serverNotices = try await Notice.fetchAll()
//
//            var allNotices = serverNotices.compactMap { notice in
//                return SystemNotice(with: notice)
//            }
//
//            allNotices.append(contentsOf: localNotices)
//
//            self.notices = allNotices.sorted()
//        } catch {
//            logDebug(error)
//        }
    }

    private func getLocalNotices() async -> [SystemNotice] {
        do {
            var notices: [SystemNotice] = []

            let connections = try await GetAllConnections().makeRequest(andUpdate: [], viewsToIgnore: [])
            notices = connections.filter({ connection in
                return connection.status == .invited && connection.from != User.current()
            }).compactMap { connection in
                return SystemNotice(withConneciton: connection)
            }

            let reservations = await Reservation.getAllUnclaimed()
            if reservations.count > 0 {
                let text = LocalizedString(id: "", arguments: [String(reservations.count)], default: "You have @(count) RSVPs left.\nTap to invite someone.")
                let reservationNotice = SystemNotice(createdAt: Date(),
                                                     notice: nil,
                                                     type: .rsvps,
                                                     priority: 2,
                                                     body: localized(text),
                                                     attributes: nil)
                notices.append(reservationNotice)
            }

            return notices
        } catch {
            return []
        }
    }

    private func subscribeToUpdates() {
//        guard let query = Notice.query() else { return }
//
//        let subscription = Client.shared.subscribe(query)
//
//        subscription.handleEvent { query, event in
//            switch event {
//            case .entered(_):
//                break
//            case .left(let obj), .deleted(let obj):
//                guard let notice = obj as? Notice else { return }
//                break
////                self.comments.remove(object: comment.systemComment)
////                runMain {
////                    self.loadSnapshot()
////                }
//            case .created(let obj):
//                guard let notice = obj as? Notice else { return }
//                break
////                var index: Int?
////                for (indx, existing) in self.comments.enumerated() {
////                    if existing.updateId == comment.updateId {
////                        index = indx
////                    }
////                }
////
////                if let indx = index {
////                    self.comments[indx] = comment.systemComment
////                } else {
////                    self.comments.append(comment.systemComment)
////                    self.comments.sort()
////                }
//
//
//            case .updated(let obj):
////                if let comment = obj as? Comment, let index = self.comments.firstIndex(of: comment.systemComment) {
////                    self.comments[index] = comment.systemComment
////                    runMain {
////                        self.loadSnapshot()
////                    }
////                }
//                break
//            }
//        }

    }
}
