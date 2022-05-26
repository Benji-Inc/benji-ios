//
//  UIViewController+Presentable.swift
//  Jibber
//
//  Created by Benji Dodgson on 1/14/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import Foundation
import Coordinator
import UIKit

//@MainActor
//protocol Presentable: AnyObject {
//
//    typealias DismissableVC = UIViewController & Dismissable
//
//    func toPresentable() -> DismissableVC
//    func removeFromParent()
//}

//extension ViewController: Presentable {
//
//    func toPresentable() -> DismissableVC {
//        return self
//    }
//}

//extension UIViewController {
//
//    /// Returns true is this view controller is being presented or added as a child view controller.
//    /// Also returns true if one of its parents meets this criteria.
//    var isBeingOpen: Bool {
//        // If a viewcontroller is being open, all of its children are too.
//        var isParentBeingOpen = false
//        if let parent = self.parent {
//            isParentBeingOpen = parent.isBeingOpen
//        }
//
//        return isParentBeingOpen ||
//            self.isBeingPresented ||
//            self.isMovingToParent ||
//            self.navigationController?.isBeingPresented ?? false
//    }
//
//    /// Returns true is this view controller is being dismissed or removed as a child view controller.
//    /// Also returns true if one of its parents meets this criteria.
//    var isBeingClosed: Bool {
//        // If a viewcontroller is being closed, all of its children are too.
//        var isParentBeingClosed = false
//        if let parent = self.parent {
//            isParentBeingClosed = parent.isBeingClosed
//        }
//
//        return isParentBeingClosed ||
//            self.isBeingDismissed ||
//            self.isMovingFromParent ||
//            self.navigationController?.isBeingDismissed ?? false
//    }
//}

//@MainActor
//protocol Dismissable: AnyObject {
//    /// Delegate closures to be called when the dismissable is dismissed. In the case of a view controller, these should be
//    /// called when the view disappears and the isBeingClosed is true.
//    var dismissHandlers: [DismissHandler] { get set }
//}
//
///// A wrapper object for a dismiss handling closure.
///// Wrapping the closure allows you to find the closure in an array and remove it.
//final class DismissHandler: Equatable {
//
//    var handler: (() -> Void)?
//
//    init() {
//        self.handler = nil
//    }
//
//    init(handler: @escaping () -> Void) {
//        self.handler = handler
//    }
//
//    static func == (lhs: DismissHandler, rhs: DismissHandler) -> Bool {
//        return lhs === rhs
//    }
//}
//
//extension Array where Element == DismissHandler {
//
//    /// A convenience function for adding a dismiss closure to an array without having to create the wrapper object.
//    /// Use this if you'll never need to remove the closure from the array.
//    mutating func append(handler: @escaping () -> Void) {
//        self.append(DismissHandler(handler: handler))
//    }
//}
