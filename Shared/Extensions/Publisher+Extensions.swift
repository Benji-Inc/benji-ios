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

extension Publisher where Self.Failure == Error {
    typealias Result = (_ value: Self.Output?, _ error: Error?) -> Void

    func mainSink(receiveValue: @escaping ((Self.Output) -> Void),
                  receiveCompletion: @escaping ((Subscribers.Completion<Error>) -> Void)) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }

    func mainSink(receiveResult: (Result)? = nil) -> AnyCancellable {
        return self.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    receiveResult?(nil, nil)
                case .failure(let error):
                    receiveResult?(nil, error)
                }
            }, receiveValue: { (value) in
                receiveResult?(value, nil)
            })
    }
}

func waitForAll<V, E: Error>(_ futures: [Future<V, E>]) -> AnyPublisher<[V], E> {
    return Publishers.MergeMany(futures).collect().eraseToAnyPublisher()
}

