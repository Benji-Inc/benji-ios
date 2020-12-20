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

