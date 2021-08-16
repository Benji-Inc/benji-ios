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

protocol Objectable: AnyObject {
    associatedtype KeyType

    func getObject<Type>(for key: KeyType) -> Type?
    func getRelationalObject<PFRelation>(for key: KeyType) -> PFRelation?
    func setObject<Type>(for key: KeyType, with newValue: Type)
    func saveLocalThenServerSync() -> Future<Self, Error>
    func saveToServerSync() -> Future<Self, Error>

    static func localThenNetworkQuerySync(for objectId: String) -> Future<Self, Error>
    static func localThenNetworkArrayQuerySync(where identifiers: [String], isEqual: Bool, container: ContainerName) -> Future<[Self], Error>
}

extension Objectable {

    static func cachedQuerySync(for objectID: String) -> Future<Self, Error> {
        return Future { promise in
            promise(.failure(ClientError.generic))
        }
    }

    static func cachedArrayQuerySync(with identifiers: [String]) -> Future<[Self], Error> {
        return Future { promise in
            promise(.failure(ClientError.generic))
        }
    }
}

extension Objectable where Self: PFObject {

    // Will save the object locally and push up to the server when ready
    @discardableResult
    func saveLocalThenServerSync() -> Future<Self, Error> {
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
    @discardableResult
    func saveToServerSync() -> Future<Self, Error> {
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

    static func fetchAll() -> Future<[Self], Never> {
        return Future { promise in
            if let query = self.query() {
                query.findObjectsInBackground { objects, error in
                    if let objs = objects as? [Self] {
                        promise(.success(objs))
                    } else {
                        promise(.success([]))
                    }
                }
            } else {
                promise(.success([]))
            }
        }
    }

    static func getFirstObject(where key: String, contains string: String) -> Future<Self, Error> {
        return Future { promise in
            let query = self.query()
            query?.whereKey(key, contains: string)
            query?.getFirstObjectInBackground(block: { object, error in
                if let obj = object as? Self {
                    promise(.success(obj))
                } else if let e = error {
                    promise(.failure(e))
                } else {
                    promise(.failure(ClientError.generic))
                }
            })
        }
    }

    static func getObject(with objectId: String) -> Future<Self, Error> {
        return self.getFirstObject(where: "objectId", contains: objectId)
    }

    static func localThenNetworkQuerySync(for objectId: String) -> Future<Self, Error> {
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

    static func localThenNetworkArrayQuerySync(where identifiers: [String],
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

    func retrieveDataFromServer() -> Future<Self, Error> {
        return Future { promise in
            self.fetchInBackground { object, error in
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
    
    func retrieveDataIfNeeded() -> Future<Self, Error> {
        return Future { promise in
            if self.isDataAvailable {
                promise(.success(self))
            } else {
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
}
