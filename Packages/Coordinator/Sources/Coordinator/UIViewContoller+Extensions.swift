//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import UIKit

extension UIViewController {
    
    /// Returns true is this view controller is being presented or added as a child view controller.
    /// Also returns true if one of its parents meets this criteria.
    public var isBeingOpen: Bool {
        // If a viewcontroller is being open, all of its children are too.
        var isParentBeingOpen = false
        if let parent = self.parent {
            isParentBeingOpen = parent.isBeingOpen
        }

        return isParentBeingOpen ||
            self.isBeingPresented ||
            self.isMovingToParent ||
            self.navigationController?.isBeingPresented ?? false
    }

    /// Returns true is this view controller is being dismissed or removed as a child view controller.
    /// Also returns true if one of its parents meets this criteria.
    public var isBeingClosed: Bool {
        // If a viewcontroller is being closed, all of its children are too.
        var isParentBeingClosed = false
        if let parent = self.parent {
            isParentBeingClosed = parent.isBeingClosed
        }

        return isParentBeingClosed ||
            self.isBeingDismissed ||
            self.isMovingFromParent ||
            self.navigationController?.isBeingDismissed ?? false
    }
    
    public func topmostViewController() -> UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topmostViewController()
        }

        if let navController = self as? UINavigationController,
            let topVC = navController.topViewController {
            return topVC
        } else if let tabBarController = self as? UITabBarController {
            if let currentVC = tabBarController.selectedViewController {
                return currentVC
            }
        }

        return self
    }
}
