//
//  MomentStore.swift
//  Jibber
//
//  Created by Benji Dodgson on 8/10/22.
//  Copyright © 2022 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseLiveQuery
import Parse
import Localization

class MomentsStore {

    static let shared = MomentsStore()
    
    @Published private(set) var todaysMoments: [Moment] = []
    
    private var __moments: [Moment] = [] {
        didSet {
            self.todaysMoments = self.__moments
        }
    }

    private var initializeTask: Task<Void, Error>?
    
    //MARK: PUBLIC

    func initializeIfNeeded() async throws {
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            try await initializeTask.value
            return
        }

        // Otherwise start a new initialization task and wait for it to finish.
        self.initializeTask = Task {
            // Get all of the notices.
            self.__moments = try await self.fetchAllOfTodaysMoments()
            
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
    
    func getTodaysMoment(withPersonId personId: String) async -> Moment? {
        try? await self.initializeIfNeeded()
        return self.todaysMoments.first { moment in
            return moment.author?.objectId == personId
        }
    }
    
    func fetchAllMoments(for person: PersonType) async throws -> [Moment] {
        return []
    }
    
    //MARK: PRIVATE
    
    private func fetchAllOfTodaysMoments() async throws -> [Moment] {
        try await PeopleStore.shared.initializeIfNeeded()
        
        var allPeople: [User] = PeopleStore.shared.allConnections
            .filter({ connection in
                return connection.status == .accepted
            })
            .compactMap { connection in
            return connection.nonMeUser
        }
        
        allPeople.insert(User.current()!, at: 0)
                
        return try await withCheckedThrowingContinuation { continuation in
            if let query = Moment.query() {
                query.whereKey("author", containedIn: allPeople)
                query.includeKey("expression")
                query.whereKey("createdAt", greaterThan: Date.today)
                query.findObjectsInBackground { objects, error in
                    if let moments = objects as? [Moment] {
                        continuation.resume(returning: moments)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ClientError.apiError(detail: "Failed to retrieve moments"))
                    }
                }
            } else {
                continuation.resume(throwing: ClientError.apiError(detail: "No query for Moments"))
            }
        }
    }
    
    private func subscribeToUpdates() {
        Client.shared.shouldPrintWebSocketLog = false

        // Query for all of todays moments.
        let query = Moment.query()!
        let subscription = Client.shared.subscribe(query)
        subscription.handleEvent { query, event in
            switch event {
            case .entered(let object), .created(let object):
                // When a new moment is made, add to the moments array.
                guard let moment = object as? Moment else { break }
                
                if !self.__moments.contains(where: { existing in
                    return existing.objectId == moment.objectId
                }) {
                    self.__moments.append(moment)
                }

            case .updated(let object):
                // When a moment is updated, we update the corresponding moment.
                guard let moment = object as? Moment else { break }
                
                if let first = self.__moments.first(where: { existing in
                    return existing.objectId == moment.objectId
                }) {
                    self.__moments.remove(object: first)
                }
                
                self.__moments.append(moment)

            case .left(let object), .deleted(let object):
                // Remove moments when they are deleted.
                guard let moment = object as? Moment else { break }

                if let first = self.__moments.first(where: { existing in
                    return existing.objectId == moment.objectId
                }) {
                    self.__moments.remove(object: first)
                }
            }
        }
    }
}

