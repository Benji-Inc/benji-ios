//
//  Ritual.swift
//  Benji
//
//  Created by Martin Young on 8/13/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Parse
import Combine
import ParseLiveQuery

enum RitualKey: String {
    case hour
    case minute
}

final class Ritual: PFObject, PFSubclassing, Subscribeable {

    static let currentKey = "currentRitualKey"
    private var cancellables = Set<AnyCancellable>()

    static func parseClassName() -> String {
        return String(describing: self)
    }

    var timeComponents: DateComponents {
        var components = DateComponents()
        components.hour = self.hour
        components.minute = self.minute
        return components
    }

    var date: Date? {
        var components = self.timeComponents
        let now = Date()
        components.year = now.year
        components.month = now.month
        components.day = now.day
        return Calendar.current.date(from: components)
    }
    
    var timeDescription: String {
        let hour = self.timeComponents.hour ?? 0
        let minute = self.timeComponents.minute ?? 0
        return "\(hour):\(minute)"
    }

    func create(with date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute],
                                                         from: date)
        self.set(components: components)
    }

    func create(with components: DateComponents) {
        self.set(components: components)
    }

    private func set(components: DateComponents) {
        if let hr = components.hour {
            self.hour = hr
        }

        if let min = components.minute {
            self.minute = min
        }
    }

    private(set) var hour: Int {
        get { return self.getObject(for: .hour) ?? 0 }
        set { self.setObject(for: .hour, with: newValue) }
    }

    private(set) var minute: Int {
        get { return self.getObject(for: .minute) ?? 0 }
        set { self.setObject(for: .minute, with: newValue) }
    }
}

extension Ritual: Objectable {
    typealias KeyType = RitualKey

    func getObject<Type>(for key: RitualKey) -> Type? {
        self.object(forKey: key.rawValue) as? Type
    }

    func setObject<Type>(for key: RitualKey, with newValue: Type) {
        self.setObject(newValue, forKey: key.rawValue)
    }

    func getRelationalObject<PFRelation>(for key: RitualKey) -> PFRelation? {
        return self.relation(forKey: key.rawValue) as? PFRelation
    }

    func saveEventually() -> Future<Ritual, Error> {
        return Future { promise in
            if let ritual = User.current()?.ritual {
                ritual.hour = self.hour
                ritual.minute = self.minute
                ritual.saveEventually()
                    .mainSink { result in
                        switch result {
                        case .success(let ritual):
                            promise(.success(ritual))
                        case .error(let error):
                            promise(.failure(error))
                        }
                    }.store(in: &self.cancellables)
            } else {
                User.current()?.ritual = self
                User.current()?.saveLocalThenServer()
                    .mainSink(receiveValue: { (_) in
                        promise(.success(self))
                    }, receiveCompletion: { (result) in
                        switch result {
                        case .finished:
                            break
                        case .failure(let e):
                            promise(.failure(e))
                        }
                    }).store(in: &self.cancellables)
            }
        }
    }
}
