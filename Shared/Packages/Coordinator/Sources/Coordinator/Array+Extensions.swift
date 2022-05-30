//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation

public extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given object
    mutating func remove(object: Element) {
        if let index = self.firstIndex(of: object) {
            self.remove(at: index)
        }
    }
}

public extension Array where Element == DismissHandler {

    /// A convenience function for adding a dismiss closure to an array without having to create the wrapper object.
    /// Use this if you'll never need to remove the closure from the array.
    mutating func append(handler: @escaping () -> Void) {
        self.append(DismissHandler(handler: handler))
    }
}
