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
    
    private var allNotices: [SystemNotice] = []

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
            self.allNotices = try await Notice.fetchAll().filter({ notice in
                return notice.type != .system
            }).compactMap({ notice in
                return SystemNotice(with: notice)
            })
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
        return self.allNotices.sorted()
    }
    
    func delete(notice: SystemNotice) {
        self.allNotices.remove(object: notice)
        
        if let n = notice.notice {
            do {
                try n.delete()
            } catch {
                logError(error)
            }
        }
    }
    
    func removeNoticeIfNeccessary(for message: Messageable) {
        guard message.deliveryType == .timeSensitive else { return }
        
        guard let first = self.allNotices.first(where: { notice in
            if notice.type == .timeSensitiveMessage,
                let msgId = notice.attributes?["messageId"] as? String,
                msgId == message.id {
                return true
            } else {
                return false
            }
        }) else { return }
        
        self.delete(notice: first)
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
                    return existing.notice?.objectId == notice.objectId
                }) {
                    self.allNotices.append(SystemNotice(with: notice))
                }

            case .updated(let object):
                // When a notice is updated, we update the corresponding notice.
                guard let notice = object as? Notice else { break }
                
                if let first = self.allNotices.first(where: { existing in
                    return existing.notice?.objectId == notice.objectId
                }) {
                    self.allNotices.remove(object: first)
                }
                
                self.allNotices.append(SystemNotice(with: notice))

            case .left(let object), .deleted(let object):
                // Remove notices when they are deleted.
                guard let notice = object as? Notice else { break }

                if let first = self.allNotices.first(where: { existing in
                    return existing.notice?.objectId == notice.objectId
                }) {
                    self.allNotices.remove(object: first)
                }
            }
        }
    }
}
