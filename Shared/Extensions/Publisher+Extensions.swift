//
//  CancellableStore.swift
//  Benji
//
//  Created by Benji Dodgson on 12/20/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Combine

extension Publisher where Self.Failure == Never {
    func mainSink(receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
    }
}

enum PublishedResult<V> {
    case success(V)
    case error(Error)
}

extension Publisher where Self.Failure == Error {

    func mainSink(receiveValue: @escaping ((Self.Output) -> Void),
                  receiveCompletion: @escaping ((Subscribers.Completion<Error>) -> Void)) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }

    func mainSink(receivedResult: @escaping (PublishedResult<Self.Output>) -> Void) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    receivedResult(.error(error))
                }
            }, receiveValue: { (value) in
                receivedResult(.success(value))
            })
    }

    func mainSink(receiveValue: ((Self.Output) -> Void)? = nil) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (_) in
                // Only listen for a value
            }, receiveValue: { (value) in
                receiveValue?(value)
            })
    }
}

func waitForAll<V, E: Error>(_ futures: [Future<V, E>]) -> AnyPublisher<[V], E> {
    return Publishers.MergeMany(futures).collect().eraseToAnyPublisher()
}

