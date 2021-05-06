//
//  Subscribeable.swift
//  Ours
//
//  Created by Benji Dodgson on 2/15/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import ParseLiveQuery
import Combine

protocol Subscribeable where Self: PFObject {
    func subscribe(andInclude key: String?, where dict: [String: Any]?) -> Future<Event<Self>, Error>
    static func subscribe<T>(where dict: [String: Any]?) -> Future<Event<T>, Error> 
}

private var subscriberKey: UInt8 = 0
extension Subscribeable where Self: PFObject {

    static func subscribe<T>(where dict: [String: Any]? = nil) -> Future<Event<T>, Error> {

        return Future { promise in

            let query = PFQuery<T>()
            if let d = dict {
                d.keys.forEach { key in
                    if let value = d[key] {
                        query.whereKey(key, equalTo: value)
                    }
                }
            }

            let subscription = Client.shared.subscribe(query)
            subscription.handleEvent { (query, event) in
                promise(.success(event))
            }

            subscription.handleError { query, error in
                promise(.failure(error))
            }
        }
    }

    func subscribe(andInclude key: String? = nil,
                   where dict: [String: Any]? = nil) -> Future<Event<Self>, Error> {

        return Future { promise in
            
            let query = Self.query() as? PFQuery<Self>
            query?.whereKey("objectId", equalTo: self.objectId!)
            if let k = key {
                query?.includeKey(k)
            }

            if let d = dict {
                d.keys.forEach { key in
                    if let value = d[key] {
                        query?.whereKey(key, equalTo: value)
                    }
                }
            }

            let subscription = Client.shared.subscribe(query!)
            subscription.handleEvent { (query, event) in
                promise(.success(event))
            }

            subscription.handleError { query, error in
                promise(.failure(error))
            }
        }
    }
}
