//
//  Router.swift
//  Router
//
//  Created by Martin Young on 8/26/21.
//  Copyright © 2021 Benjamin Dodgson. All rights reserved.
//

import UIKit
import Coordinator

/// An object that can present Presentable objects via a navigation controller push, or modally.
/// Optionally, a cancel handler can be provided to execute code when the Presentable is dismissed
/// prematurely by something other than the router.
class Router: CoordinatorRouter {
    
    var deepLink: DeepLinkable?

    init(navController: UINavigationController, deepLink: DeepLinkable? = nil) {
        self.deepLink = deepLink
        super.init(navController: navController, modalTransitionRouter: ModalTransitionController())
    }

    // MARK: UINavigationControllerDelegate

    override func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        guard let from = fromVC as? TransitionableViewController,
              let to = toVC as? TransitionableViewController else {
            return super.navigationController(navigationController,
                                              animationControllerFor: operation,
                                              from: fromVC,
                                              to: toVC)
        }

        return TransitionRouter(fromVC: from, toVC: to, operation: operation)
    }
}
