//
//  File.swift
//  
//
//  Created by Benji Dodgson on 5/26/22.
//

import Foundation
import UIKit

extension UIViewController {
    
    func topmostViewController() -> UIViewController {
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
