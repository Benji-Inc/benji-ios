//
//  NoticeStore.swift
//  Jibber
//
//  Created by Benji Dodgson on 4/1/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseLiveQuery
import Parse
import Localization

class NoticeStore {

    static let shared = NoticeStore()
    
    private var allNotices: [Notice] = []

    private var initializeTask: Task<Void, Error>?

    func initializeIfNeeded() async throws {
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            try await initializeTask.value
            return
        }

        // Otherwise start a new initialization task and wait for it to finish.
        self.initializeTask = Task {
            // Get all of the notices.
            self.allNotices = try await Notice.fetchAll()
            self.subscribeToUpdates()
        }

        do {
            try await self.initializeTask?.value
        } catch {
            // Dispose of the task because it failed, then pass the error along.
            self.initializeTask = nil
            throw error
        }
    }
     
    func getAllNotices() -> [SystemNotice] {
        let existing = self.allNotices
            .compactMap { notice in
            return SystemNotice(with: notice)
        }.sorted()
        return existing
    }
    
    private func subscribeToUpdates() {
        Client.shared.shouldPrintWebSocketLog = false

        // Query for all notices related to the user.
        let query = Notice.query()!
        let subscription = Client.shared.subscribe(query)
        subscription.handleEvent { query, event in
            switch event {
            case .entered(let object), .created(let object):
                // When a new notice is made, add to the notices array.
                guard let notice = object as? Notice else { break }
                
                if !self.allNotices.contains(where: { existing in
                    return existing.objectId == notice.objectId
                }) {
                    self.allNotices.append(notice)
                }

            case .updated(let object):
                // When a notice is updated, we update the corresponding notice.
                guard let notice = object as? Notice else { break }
                
                if let first = self.allNotices.first(where: { existing in
                    return existing.objectId == notice.objectId
                }) {
                    self.allNotices.remove(object: first)
                }
                
                self.allNotices.append(notice)

            case .left(let object), .deleted(let object):
                // Remove notices when they are deleted.
                guard let notice = object as? Notice else { break }

                if let first = self.allNotices.first(where: { existing in
                    return existing.objectId == notice.objectId
                }) {
                    self.allNotices.remove(object: first)
                }
            }
        }
    }
}
