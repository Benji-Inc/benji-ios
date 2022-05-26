//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation

@MainActor
public protocol Dismissable: AnyObject {
    /// Delegate closures to be called when the dismissable is dismissed. In the case of a view controller, these should be
    /// called when the view disappears and the isBeingClosed is true.
    var dismissHandlers: [DismissHandler] { get set }
}

/// A wrapper object for a dismiss handling closure.
/// Wrapping the closure allows you to find the closure in an array and remove it.
public final class DismissHandler: Equatable {

    var handler: (() -> Void)?

    init() {
        self.handler = nil
    }

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    public static func == (lhs: DismissHandler, rhs: DismissHandler) -> Bool {
        return lhs === rhs
    }
}
