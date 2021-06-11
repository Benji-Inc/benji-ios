//
//  NoticeSupplier.swift
//  Ours
//
//  Created by Benji Dodgson on 5/29/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseLiveQuery
import Parse

class NoticeSupplier {

    static let shared = NoticeSupplier()

    enum NoticeStatus {
        case deleted(SystemNotice)
        case updated(SystemNotice)
        case created(SystemNotice)
    }

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var notices: [SystemNotice] = []
    @Published private(set) var noticeStatus: NoticeStatus? = nil

    init() {
        self.loadNotices()
    }

    deinit {
        self.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    func loadNotices() {

        let combined = Publishers.Zip(
            self.getLocalNotices(),
            Notice.fetchAll()
        )

        combined.mainSink { (local, server) in
            var notices = server.compactMap { notice in
                return SystemNotice(with: notice)
            }

            notices.append(contentsOf: local)
            self.notices = notices.sorted()

        }.store(in: &self.cancellables)
    }

    private func getLocalNotices() -> Future<[SystemNotice], Never> {
        return Future { promise in
            promise(.success([]))
        }
    }

    private func subscribeToUpdates() {
        guard let query = Notice.query() else { return }

        let subscription = Client.shared.subscribe(query)

        subscription.handleEvent { query, event in
            switch event {
            case .entered(_):
                break
            case .left(let obj), .deleted(let obj):
                guard let notice = obj as? Notice else { return }
                break
//                self.comments.remove(object: comment.systemComment)
//                runMain {
//                    self.loadSnapshot()
//                }
            case .created(let obj):
                guard let notice = obj as? Notice else { return }
                break
//                var index: Int?
//                for (indx, existing) in self.comments.enumerated() {
//                    if existing.updateId == comment.updateId {
//                        index = indx
//                    }
//                }
//
//                if let indx = index {
//                    self.comments[indx] = comment.systemComment
//                } else {
//                    self.comments.append(comment.systemComment)
//                    self.comments.sort()
//                }


            case .updated(let obj):
//                if let comment = obj as? Comment, let index = self.comments.firstIndex(of: comment.systemComment) {
//                    self.comments[index] = comment.systemComment
//                    runMain {
//                        self.loadSnapshot()
//                    }
//                }
                break
            }
        }

    }
}
