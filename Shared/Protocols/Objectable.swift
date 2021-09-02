//
//  Objectable.swift
//  Benji
//
//  Created by Benji Dodgson on 11/3/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine

enum ContainerName {
    case conversation(identifier: String)
    case favorites

    var name: String {
        switch self {
        case .conversation(let identifier):
            return "conversation\(identifier)"
        case .favorites:
            return "favorites"
        }
    }
}

protocol Objectable: AnyObject {
    associatedtype KeyType

    func getObject<Type>(for key: KeyType) -> Type?
    func getRelationalObject<PFRelation>(for key: KeyType) -> PFRelation?
    func setObject<Type>(for key: KeyType, with newValue: Type)

    func saveLocalThenServer() async throws -> Self
    func saveToServer() async throws -> Self

    static func localThenNetworkQuery(for objectId: String) async throws -> Self
    static func localThenNetworkArrayQuery(where identifiers: [String],
                                           isEqual: Bool,
                                           container: ContainerName) async throws -> [Self]
}

extension Objectable where Self: PFObject {

    @discardableResult
    func saveLocalThenServer() async throws -> Self {
        let object: Self = try await withCheckedThrowingContinuation { continuation in
            self.saveEventually { (success, error) in
                if let error = error {
                    SessionManager.shared.handleParse(error: error)
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: self)
                }
            }
        }

        return object
    }

    @discardableResult
    func saveToServer() async throws -> Self {
        let object: Self = try await withCheckedThrowingContinuation { continuation in
            self.saveInBackground { (success, error) in
                if let error = error {
                    SessionManager.shared.handleParse(error: error)
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: self)
                }
            }
        }

        return object
    }

    static func getFirstObject(where key: String, contains string: String) async throws -> Self {
        let object: Self = try await withCheckedThrowingContinuation { continuation in
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
                return
            }
            query.whereKey(key, contains: string)
            query.getFirstObjectInBackground(block: { object, error in
                if let obj = object as? Self {
                    continuation.resume(returning: obj)
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(throwing: ClientError.generic)
                }
            })
        }

        return object
    }

    static func getObject(with objectId: String) async throws -> Self {
        let object = try await self.getFirstObject(where: "objectId", contains: objectId)
        return object
    }

    static func fetchAll() async throws -> [Self] {
        let objects: [Self] = try await withCheckedThrowingContinuation { continuation in
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.apiError(detail: "Query was nil"))
                return
            }

            query.findObjectsInBackground { objects, error in
                if let objs = objects as? [Self] {
                    continuation.resume(returning: objs)
                } else if let e = error {
                    continuation.resume(throwing: e)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }

        return objects
    }

    static func localThenNetworkQuery(for objectId: String) async throws -> Self {
        let object: Self = try await withCheckedThrowingContinuation { continuation in
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.message(detail: "Unable get query for object"))
                return
            }

            query.fromPin(withName: objectId)
            query.getFirstObjectInBackground()
                .continueWith { (task) -> Any? in
                    if let object = task.result as? Self {
                        continuation.resume(returning: object)
                    } else if let nonCacheQuery = self.query() {
                        nonCacheQuery.whereKey(ObjectKey.objectId.rawValue, equalTo: objectId)
                        nonCacheQuery.getFirstObjectInBackground { (object, error) in
                            if let nonCachedObject = object as? Self, let identifier = nonCachedObject.objectId {
                                nonCachedObject.pinInBackground(withName: identifier) { (success, error) in
                                    if let e = error {
                                        SessionManager.shared.handleParse(error: e)
                                        continuation.resume(throwing: e)
                                    } else {
                                        continuation.resume(returning: nonCachedObject)
                                    }
                                }
                            } else if let e = error {
                                SessionManager.shared.handleParse(error: e)
                                continuation.resume(throwing: e)
                            } else {
                                continuation.resume(throwing: ClientError.generic)
                            }
                        }
                    } else {
                        continuation.resume(throwing: ClientError.generic)
                    }

                    return nil
                }
        }

        return object
    }

    static func localThenNetworkArrayQuery(where identifiers: [String],
                                           isEqual: Bool,
                                           container: ContainerName) async throws -> [Self] {

        let array: [Self] = try await withCheckedThrowingContinuation { continuation in
            guard let query = self.query() else {
                continuation.resume(throwing: ClientError.message(detail: "Unable get query for object"))
                return
            }
            query.fromPin(withName: container.name)
            query.findObjectsInBackground()
                .continueWith { (task) -> Any? in
                    if let objects = task.result as? [Self], !objects.isEmpty, objects.count == identifiers.count {
                        continuation.resume(returning: objects)
                    } else if let nonCacheQuery = self.query() {
                        if isEqual {
                            nonCacheQuery.whereKey(ObjectKey.objectId.rawValue, containedIn: identifiers)
                        } else {
                            nonCacheQuery.whereKey(ObjectKey.objectId.rawValue, notContainedIn: identifiers)
                        }
                        nonCacheQuery.findObjectsInBackground { (objects, error) in
                            PFObject.pinAll(inBackground: objects, withName: container.name) { (success, error) in
                                if let e = error {
                                    SessionManager.shared.handleParse(error: e)
                                    continuation.resume(throwing: e)
                                } else if let objectsForType = objects as? [Self] {
                                    continuation.resume(returning: objectsForType)
                                } else {
                                    continuation.resume(throwing: ClientError.generic)
                                }
                            }
                        }
                    } else {
                        continuation.resume(throwing: ClientError.generic)
                    }

                    return nil
                }
        }

        return array
    }

    func retrieveDataIfNeeded() async throws -> Self {
        let object: Self = try await withCheckedThrowingContinuation { continuation in
            if self.isDataAvailable {
                continuation.resume(returning: self)
            } else {
                self.fetchIfNeededInBackground { (object, error) in
                    if let e = error {
                        SessionManager.shared.handleParse(error: e)
                        continuation.resume(throwing: e)
                    } else if let objectWithData = object as? Self {
                        continuation.resume(returning: objectWithData)
                    } else {
                        continuation.resume(throwing: ClientError.generic)
                    }
                }
            }
        }
        return object
    }
}
