//
//  Equatable+Extensions.swift
//  Jibber
//
//  Created by Martin Young on 10/6/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation

extension Equatable {

    /// Returns true if self is equal to one of the passed in values.
    func equalsOneOf(these: Self...) -> Bool {
        return these.contains(self)
    }
}
