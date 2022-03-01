//
//  UserStore.swift
//  Jibber
//
//  Created by Benji Dodgson on 10/22/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine
import ParseLiveQuery
import Parse
import StreamChat
import Contacts

/// A store that contains all people that the user has some relationship with. This could take the form of a directly connected Jibber chat user
/// or it could just be another person that has been invited but not yet joined Jibber.
class PeopleStore {

    static let shared = PeopleStore()

    @Published var personUpdated: PersonType?
    @Published var userDeleted: User?

    var people: [PersonType] {
        var allPeople: [PersonType] = self.users
        let contactPeople: [PersonType] = self.contacts.map { contact in
            return Person(withContact: contact)
        }
        allPeople.append(contentsOf: contactPeople)
        return allPeople
    }
    private(set) var users: [User] = []
    private(set) var contacts: [CNContact] = []

    private var initializeTask: Task<Void, Never>?

    func initializeIfNeeded() async {
        // If we already have an initialization task, wait for it to finish.
        if let initializeTask = self.initializeTask {
            await initializeTask.value
            return
        }

        // Otherwise start a new initialization task and wait for it to finish.
        self.initializeTask = Task {
            // Get all of the connections and unclaimed reservations.
            await self.getAndStoreAllConnectedUsers()

            await self.getAndStoreAllContactsWithUnclaimedReservations()

            self.subscribeToUpdates()
        }

        await self.initializeTask?.value
    }

    private func getAndStoreCurrentUser() {
        guard let current = User.current() else { return }
        self.users.append(current)
    }
    
    private func getAndStoreAllConnectedUsers() async {
        do {
            let connections = try await GetAllConnections().makeRequest(andUpdate: [],
                                                                        viewsToIgnore: [])
                .filter { (connection) -> Bool in
                    return !connection.nonMeUser.isNil
                }
            
            var unfetchedUserIds = connections.compactMap { connection in
                return connection.nonMeUser?.objectId
            }
            
            if let current = User.current()?.objectId {
                unfetchedUserIds.append(current)
            }
            
            if let users = try? await User.fetchAndUpdateLocalContainer(where: unfetchedUserIds,
                                                                             container: .users) {
                self.users = users
            }
        } catch {
            logError(error)
        }
    }

    private func getAndStoreAllContactsWithUnclaimedReservations() async {
        let reservations = await Reservation.getAllUnclaimed()
        reservations.forEach { reservation in
            guard let contactId = reservation.contactId else { return }
            guard let contact =
                    ContactsManger.shared.searchForContact(with: .identifier(contactId)).first else {
                        return
                    }
            self.contacts.append(contact)
        }
    }

    private func subscribeToUpdates() {
        Client.shared.shouldPrintWebSocketLog = false

        // Query for all connections related to the user. Either sent to OR from.
        let toQuery = Connection.query()!.whereKey("to", equalTo: User.current()!)
        let fromQuery = Connection.query()!.whereKey("from", equalTo: User.current()!)
        let orQuery = PFQuery.orQuery(withSubqueries: [toQuery, fromQuery])
        let connectionSubscription = Client.shared.subscribe(orQuery)
        connectionSubscription.handleEvent { query, event in
            switch event {
            case .entered(let object), .created(let object):
                // When a new connection is made, add the connected to the array.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }

                self.users.append(nonMeUser)
            case .updated(let object):
                // When a connection is updated, we update the corresponding user.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }
                self.personUpdated = nonMeUser

                if let indexToUpdate = self.users.firstIndex(where: { user in
                    return user.personId == nonMeUser.personId
                }) {
                    self.users[indexToUpdate] = nonMeUser
                }
            case .left(let object), .deleted(let object):
                // Remove users when their connections are deleted.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }

                self.users.removeAll { user in
                    return user.personId == nonMeUser.personId
                }
                self.userDeleted = nonMeUser
            }
        }

        // Observe changes to all unclaimed reservations that the user owns.
        let reservationQuery = Reservation.query()!
        reservationQuery.whereKey(ReservationKey.createdBy.rawValue, equalTo: User.current()!)
        let reservationSubscription = Client.shared.subscribe(reservationQuery)
        reservationSubscription.handleEvent { query, event in
            switch event {
            case .entered(let object), .created(let object):
                // When a new connection is made, add the connected to the array.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }

                self.users.append(nonMeUser)
            case .updated(let object):
                // When a connection is updated, we update the corresponding user.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }
                self.personUpdated = nonMeUser

                if let indexToUpdate = self.users.firstIndex(where: { user in
                    return user.personId == nonMeUser.personId
                }) {
                    self.users[indexToUpdate] = nonMeUser
                }
            case .left(let object), .deleted(let object):
                // Remove users when their connections are deleted.
                guard let connection = object as? Connection,
                      let nonMeUser = connection.nonMeUser else { break }

                self.users.removeAll { user in
                    return user.personId == nonMeUser.personId
                }
                self.userDeleted = nonMeUser
            }
        }
    }

    // MARK: - Helper functions

    func getPeople(for members: [ConversationMember]) async throws -> [PersonType] {
        var people: [PersonType] = []
        await members.userIDs.asyncForEach { userId in
            guard let person = await self.getPerson(withPersonId: userId) else { return }
            people.append(person)
        }
        
        return people
    }

    func getPerson(withPersonId personId: String) async -> PersonType? {
        var foundUser: User? = nil

        if let user = PeopleStore.shared.users.first(where: { user in
            return user.objectId == personId
        }) {
            foundUser = user
        } else if let user = try? await User.getObject(with: personId) {
            foundUser = user
        }
        
        return foundUser
    }
}
