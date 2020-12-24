//
//  Delegated.swift
//  Benji
//
//  Created by Benji Dodgson on 12/24/20.
//  Copyright © 2020 Benjamin Dodgson. All rights reserved.
//

import Foundation

@propertyWrapper
final class Delegated<Input> {

    init() {
        self.callback = { _ in }
    }

    private var callback: (Input) -> Void

    var wrappedValue: (Input) -> Void {
        return self.callback
    }

    var projectedValue: Delegated<Input> {
        return self
    }

    func delegate<Target: AnyObject>(
        to target: Target,
        with callback: @escaping (Target, Input) -> Void
    ) {
        self.callback = { [weak target] input in
            guard let target = target else {
                return
            }
            return callback(target, input)
        }
    }
}
