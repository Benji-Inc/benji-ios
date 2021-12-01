//
//  ClosedRange+Extensions.swift
//  Benji
//
//  Created by Benji Dodgson on 6/30/19.
//  Copyright © 2019 Benjamin Dodgson. All rights reserved.
//

import Foundation

// MARK: - Open Range

extension Range where Bound: Numeric {

    /// Gets the one dimensional vector from the range to the specified value.
    /// If the value is contained within the range, then zero is returned.
    func vector(to value: Bound) -> Bound {
        if value < self.lowerBound {
            return value - self.lowerBound
        } else if value > self.upperBound {
            return value - self.upperBound
        }

        return Bound.zero
    }
}

// MARK: - Closed Range

extension ClosedRange {

    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
