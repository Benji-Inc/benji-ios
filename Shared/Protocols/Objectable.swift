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
    case channel(identifier: String)
    case favorites

    var name: String {
        switch self {
        case .channel(let identifier):
            return "channel\(identifier)"
        case .favorites:
            return "favorites"
        }
    }
}

protocol Objectable: class {
    associatedtype KeyType

    func getObject<Type>(for key: KeyType) -> Type?
    func getRelationalObject<PFRelation>(for key: KeyType) -> PFRelation?
    func setObject<Type>(for key: KeyType, with newValue: Type)
    func saveLocalThenServer() -> Future<Self, Error>
    func saveToServer() -> Future<Self, Error>

    static func localThenNetworkQuery(for objectId: String) -> Future<Self, Error>
    static func localThenNetworkArrayQuery(where identifiers: [String], isEqual: Bool, container: ContainerName) -> Future<[Self], Error>
}

extension Objectable {

    static func cachedQuery(for objectID: String) -> Future<Self, Error> {
        return Future { promise in
            promise(.failure(ClientError.generic))
        }
    }

    static func cachedArrayQuery(with identifiers: [String]) -> Future<[Self], Error> {
        return Future { promise in
            promise(.failure(ClientError.generic))
        }
    }
}

extension Objectable where Self: PFObject {

    // Will save the object locally and push up to the server when ready
    func saveLocalThenServer() -> Future<Self, Error> {
        return Future { promise in
            self.saveEventually { (success, error) in
                if let e = error {
                    SessionManager.shared.handleParse(error: e)
                    promise(.failure(e))
                } else {
                    promise(.success(self))
                }
            }
        }
    }

    // Does not save locally but just pushes to server in the background
    func saveToServer() -> Future<Self, Error> {
        return Future { promise in
            self.saveInBackground { (success, error) in
                if let e = error {
                    SessionManager.shared.handleParse(error: e)
                    promise(.failure(e))
                } else {
                    promise(.success(self))
                }
            }
        }
    }

    static func localThenNetworkQuery(for objectId: String) -> Future<Self, Error> {
        return Future { promise in
            if let query = self.query() {
                query.fromPin(withName: objectId)
                query.getFirstObjectInBackground()
                    .continueWith { (task) -> Any? in
                        if let object = task.result as? Self {
                            promise(.success(object))
                        } else if let nonCacheQuery = self.query() {
                            nonCacheQuery.whereKey(ObjectKey.objectId.rawValue, equalTo: objectId)
                            nonCacheQuery.getFirstObjectInBackground { (object, error) in
                                if let nonCachedObject = object as? Self, let identifier = nonCachedObject.objectId {
                                    nonCachedObject.pinInBackground(withName: identifier) { (success, error) in
                                        if let e = error {
                                            SessionManager.shared.handleParse(error: e)
                                            promise(.failure(e))
                                        } else {
                                            promise(.success(nonCachedObject))
                                        }
                                    }
                                } else if let e = error {
                                    SessionManager.shared.handleParse(error: e)
                                    promise(.failure(e))
                                } else {
                                    promise(.failure(ClientError.generic))
                                }
                            }
                        } else {
                            promise(.failure(ClientError.generic))
                        }

                        return nil
                    }
            }
        }
    }

    static func localThenNetworkArrayQuery(where identifiers: [String],
                                           isEqual: Bool,
                                           container: ContainerName) -> Future<[Self], Error> {
        return Future { promise in
            if let query = self.query() {
                query.fromPin(withName: container.name)
                query.findObjectsInBackground()
                    .continueWith { (task) -> Any? in
                        if let objects = task.result as? [Self], !objects.isEmpty, objects.count == identifiers.count {
                            promise(.success(objects))
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
                                        promise(.failure(e))
                                    } else if let objectsForType = objects as? [Self] {
                                        promise(.success(objectsForType))
                                    } else {
                                        promise(.failure(ClientError.generic))
                                    }
                                }
                            }
                        } else {
                            promise(.failure(ClientError.generic))
                        }

                        return nil
                    }
            }
        }
    }
    
    func retrieveDataIfNeeded() -> Future<Self, Error> {
        return Future { promise in
            self.fetchIfNeededInBackground { (object, error) in
                if let e = error {
                    SessionManager.shared.handleParse(error: e)
                    promise(.failure(e))
                } else if let objectWithData = object as? Self {
                    promise(.success(objectWithData))
                } else {
                    promise(.failure(ClientError.generic))
                }
            }
        }
    }
}
